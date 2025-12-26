// FILE #48
// lib/src/core/di/di.dart

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/core/auth/auth_module.dart';
import 'package:movi/src/core/config/config.dart';
import 'package:movi/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart';
import 'package:movi/src/features/iptv/data/services/iptv_credentials_edge_service.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/logging/logging_module.dart';
import 'package:movi/src/core/network/config/network_module.dart';
import 'package:movi/src/core/network/network.dart';
import 'package:movi/src/core/preferences/preferences.dart';
import 'package:movi/src/core/profile/data/repositories/supabase_profile_repository.dart';
import 'package:movi/src/core/performance/performance_module.dart';
import 'package:movi/src/core/state/state.dart';
import 'package:movi/src/core/parental/data/datasources/tmdb_content_rating_remote_data_source.dart';
import 'package:movi/src/core/parental/data/datasources/pin_recovery_remote_data_source.dart';
import 'package:movi/src/core/parental/data/repositories/cached_content_rating_repository.dart';
import 'package:movi/src/core/parental/data/repositories/pin_recovery_repository_impl.dart';
import 'package:movi/src/core/parental/data/services/profile_pin_edge_service.dart';
import 'package:movi/src/core/parental/domain/repositories/content_rating_repository.dart';
import 'package:movi/src/core/parental/domain/repositories/pin_recovery_repository.dart';
import 'package:movi/src/core/parental/domain/services/age_policy.dart';
import 'package:movi/src/core/parental/application/services/parental_session_service.dart';
import 'package:movi/src/core/parental/domain/services/playlist_maturity_classifier.dart';
import 'package:movi/src/core/reporting/application/usecases/report_content_problem.dart';
import 'package:movi/src/core/reporting/data/repositories/supabase_content_reports_repository.dart';
import 'package:movi/src/core/reporting/domain/repositories/content_reports_repository.dart';
import 'package:movi/src/core/storage/services/storage_module.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/core/supabase/supabase_module.dart';
import 'package:movi/src/core/profile/data/datasources/supabase_profile_datasource.dart';
import 'package:movi/src/core/startup/app_launch_orchestrator.dart';

import 'package:movi/src/features/category_browser/data/category_browser_data_module.dart';
import 'package:movi/src/features/home/data/home_feed_data_module.dart';
import 'package:movi/src/features/iptv/data/iptv_data_module.dart';
import 'package:movi/src/features/library/data/library_data_module.dart';
import 'package:movi/src/features/library/application/services/cloud_sync_preferences.dart';
import 'package:movi/src/features/movie/data/movie_data_module.dart';
import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
import 'package:movi/src/features/person/data/person_data_module.dart';
import 'package:movi/src/features/playlist/data/playlist_data_module.dart';
import 'package:movi/src/features/saga/data/saga_data_module.dart';
import 'package:movi/src/features/search/data/search_data_module.dart';
import 'package:movi/src/features/settings/data/settings_data_module.dart';
import 'package:movi/src/features/tv/data/tv_data_module.dart';
import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';

import 'package:movi/src/shared/data/services/tmdb_cache_data_source.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/data/services/iptv_content_resolver_impl.dart';
import 'package:movi/src/shared/data/services/xtream_lookup_service.dart';
import 'package:movi/src/shared/domain/services/iptv_content_resolver.dart';
import 'package:movi/src/shared/domain/services/playlist_tmdb_enrichment_service.dart';
import 'package:movi/src/shared/domain/services/similarity_service.dart';
import 'package:movi/src/shared/domain/services/tmdb_cache_store.dart';
import 'package:movi/src/shared/domain/services/tmdb_http_client.dart';
import 'package:movi/src/shared/domain/services/tmdb_id_resolver_service.dart';
import 'package:movi/src/shared/domain/services/xtream_lookup.dart';

/// Global service locator.
final sl = GetIt.instance;

/// Replace or register a singleton.
void replace<T extends Object>(T instance) {
  if (sl.isRegistered<T>()) {
    sl.unregister<T>();
  }
  sl.registerSingleton<T>(instance);
}

/// Entry point for dependency initialization.
Future<void> initDependencies({
  AppConfig? appConfig,
  SecretStore? secretStore,
  LocaleCodeProvider? localeProvider,
  bool registerFeatureModules = true,
}) async {
  await _registerConfig(appConfig);
  _registerSecretStore(secretStore);

  await _registerPreferences();
  _registerLoggingIfReady();

  await StorageModule.register();
  await _registerCloudSyncPreferences();
  await _registerNetwork(localeProvider);
  await PerformanceModule.register(sl);

  _registerTmdbInfrastructure();
  _registerSharedServices();

  // IMPORTANT:
  // AppStateController must be registered before Auth/Supabase modules.
  _registerState();

  // --------------------------------------------------------------------------
  // Supabase/Auth wiring (single client rule)
  // --------------------------------------------------------------------------
  //
  // Goal:
  // - Ensure the app uses the SAME SupabaseClient everywhere (auth + repositories),
  //   via GetIt: sl<SupabaseClient>().
  // - Ensure the URL/anonKey used by the app matches the project where your DB lives.
  //
  // SupabaseModule is responsible for:
  // - validating config (fail-fast)
  // - initializing Supabase (idempotent)
  // - registering SupabaseClient singleton into GetIt
  await SupabaseModule.register(sl);

  // Register Supabase-backed repositories in GetIt (needed by bootstrap/preload).
  _registerSupabaseRepositories();

  // AuthModule should rely on sl<SupabaseClient>() (single client rule).
  AuthModule.register(sl);

  if (registerFeatureModules) {
    _registerFeatureModules();
  }

  // Optional fail-fast diagnostics (debug only): catch "GetIt not registered" early.
  _assertCriticalRegistrations();
}

/* -------------------------------------------------------------------------- */
/* Config & base services                                                      */
/* -------------------------------------------------------------------------- */

Future<void> _registerConfig(AppConfig? config) async {
  if (config == null) return;

  if (sl.isRegistered<AppLogger>()) {
    await LoggingModule.dispose();
  }

  replace<AppConfig>(config);
}

void _registerSecretStore(SecretStore? store) {
  if (store != null) {
    replace<SecretStore>(store);
    return;
  }

  if (!sl.isRegistered<SecretStore>()) {
    sl.registerLazySingleton<SecretStore>(() => SecretStore());
  }
}

Future<void> _registerPreferences() async {
  await _registerLocalePreferences();
  await _registerSelectedProfilePreferences();
  await _registerSelectedIptvSourcePreferences();
  await _registerIptvSyncPreferences();
  await _registerPlayerPreferences();
  await _registerAccentColorPreferences();
}

Future<void> _registerLocalePreferences() async {
  if (sl.isRegistered<LocalePreferences>()) return;

  final locale = ui.PlatformDispatcher.instance.locale;
  final deviceCode = '${locale.languageCode}-${locale.countryCode ?? 'US'}';
  
  // Vérifier si la langue de l'appareil est supportée, sinon fallback sur anglais
  final supportedLocales = const [
    'en', 'en-US', 'en-GB',
    'es', 'es-ES',
    'fr', 'fr-FR', 'fr-MM',
    'de', 'de-DE',
    'it', 'it-IT',
    'nl', 'nl-NL',
    'pl', 'pl-PL',
    'pt', 'pt-PT', 'pt-BR',
  ];
  
  // Normaliser le code de langue de l'appareil
  final normalizedDeviceCode = deviceCode.toLowerCase();
  final deviceLangCode = locale.languageCode.toLowerCase();
  
  // Vérifier si la langue complète est supportée, sinon vérifier juste le code langue
  String? supportedCode;
  if (supportedLocales.any((s) => s.toLowerCase() == normalizedDeviceCode)) {
    supportedCode = deviceCode;
  } else if (supportedLocales.any((s) => s.toLowerCase().startsWith('$deviceLangCode-'))) {
    // Trouver le premier code supporté pour cette langue
    supportedCode = supportedLocales.firstWhere(
      (s) => s.toLowerCase().startsWith('$deviceLangCode-'),
      orElse: () => deviceLangCode,
    );
  } else {
    // Fallback sur anglais si la langue n'est pas supportée
    supportedCode = 'en-US';
  }

  final prefs = await LocalePreferences.create(defaultLanguageCode: supportedCode);
  sl.registerSingleton<LocalePreferences>(prefs);
}

Future<void> _registerSelectedProfilePreferences() async {
  if (sl.isRegistered<SelectedProfilePreferences>()) return;

  final prefs = await SelectedProfilePreferences.create();
  sl.registerSingleton<SelectedProfilePreferences>(prefs);
}

Future<void> _registerSelectedIptvSourcePreferences() async {
  if (sl.isRegistered<SelectedIptvSourcePreferences>()) return;

  final prefs = await SelectedIptvSourcePreferences.create();
  sl.registerSingleton<SelectedIptvSourcePreferences>(prefs);
}

Future<void> _registerIptvSyncPreferences() async {
  if (sl.isRegistered<IptvSyncPreferences>()) return;

  final prefs = await IptvSyncPreferences.create();
  sl.registerSingleton<IptvSyncPreferences>(prefs);
}

Future<void> _registerPlayerPreferences() async {
  if (sl.isRegistered<PlayerPreferences>()) return;

  final prefs = await PlayerPreferences.create();
  sl.registerSingleton<PlayerPreferences>(prefs);
}

Future<void> _registerAccentColorPreferences() async {
  if (sl.isRegistered<AccentColorPreferences>()) return;

  final prefs = await AccentColorPreferences.create();
  sl.registerSingleton<AccentColorPreferences>(prefs);
}

Future<void> _registerCloudSyncPreferences() async {
  if (sl.isRegistered<CloudSyncPreferences>()) return;

  final storage = sl<SecureStorageRepository>();
  final prefs = await CloudSyncPreferences.create(storage: storage);
  sl.registerSingleton<CloudSyncPreferences>(prefs);
}

/* -------------------------------------------------------------------------- */
/* Logging & network                                                           */
/* -------------------------------------------------------------------------- */

void _registerLoggingIfReady() {
  if (sl.isRegistered<AppConfig>()) {
    LoggingModule.register();
  }
}

Future<void> _registerNetwork(LocaleCodeProvider? localeProvider) async {
  if (!sl.isRegistered<AppConfig>()) return;
  final config = sl<AppConfig>();
  final secretStore = sl<SecretStore>();
  NetworkModule.register(
    localeProvider: localeProvider,
    authTokenProvider: _buildTmdbTokenProvider(config.network, secretStore),
  );
}

AuthTokenProvider? _buildTmdbTokenProvider(
  NetworkEndpoints endpoints,
  SecretStore secretStore,
) {
  final host = endpoints.resolvedTmdbBaseHost.toLowerCase();

  return MemoizedTokenProvider(
    loader: () async {
      final configured = endpoints.tmdbApiKey?.trim();
      if (configured != null && configured.isNotEmpty) {
        if (_isV3Key(configured)) return null;
        return configured;
      }
      final secret = await secretStore.read('TMDB_API_KEY');
      if (secret == null || secret.isEmpty) return null;
      if (_isV3Key(secret)) return null;
      return secret;
    },
    appliesTo: (request) => request.uri.host.toLowerCase() == host,
  );
}

bool _isV3Key(String key) => !key.startsWith('eyJ') && key.length <= 64;

/* -------------------------------------------------------------------------- */
/* Supabase repositories (bootstrap critical)                                  */
/* -------------------------------------------------------------------------- */

void _registerSupabaseRepositories() {
  // Ensure a single SupabaseClient exists (provided by SupabaseModule).
  if (!sl.isRegistered<SupabaseClient>()) {
    // If SupabaseClient is not registered, it means SupabaseModule.register() was skipped
    // (Supabase not configured). Don't use fallback as it would throw if Supabase not initialized.
    const config = SupabaseConfig.fromEnvironment;
    if (!config.isConfigured) {
      // Supabase not configured, skip repository registration
      return;
    }
    // If configured but not registered, this is a sequence error
    throw StateError(
      'SupabaseClient should be registered by SupabaseModule before calling _registerSupabaseRepositories',
    );
  }

  if (!sl.isRegistered<SupabaseProfileRepository>()) {
    sl.registerLazySingleton<SupabaseProfileRepository>(() {
      final client = sl<SupabaseClient>();
      final ds = SupabaseProfileDatasource(client);
      return SupabaseProfileRepository(client, datasource: ds);
    });
  }

  if (!sl.isRegistered<SupabaseIptvSourcesRepository>()) {
    sl.registerLazySingleton<SupabaseIptvSourcesRepository>(
      () => SupabaseIptvSourcesRepository(sl<SupabaseClient>()),
    );
  }

  if (!sl.isRegistered<IptvCredentialsEdgeService>()) {
    sl.registerLazySingleton<IptvCredentialsEdgeService>(
      () => IptvCredentialsEdgeService(sl<SupabaseClient>()),
    );
  }

  if (!sl.isRegistered<ContentReportsRepository>()) {
    sl.registerLazySingleton<ContentReportsRepository>(
      () => SupabaseContentReportsRepository(sl<SupabaseClient>()),
    );
  }

  if (!sl.isRegistered<ReportContentProblem>() &&
      sl.isRegistered<ContentReportsRepository>()) {
    sl.registerLazySingleton<ReportContentProblem>(
      () => ReportContentProblem(sl<ContentReportsRepository>()),
    );
  }

  // IPTV local repo is also needed by bootstrap; if a module registers it later,
  // bootstrap may run too early. Ensure it exists here (if StorageModule didn't).
  if (!sl.isRegistered<IptvLocalRepository>() &&
      sl.isRegistered<ContentCacheRepository>()) {
    // NOTE: If your project registers IptvLocalRepository elsewhere with its own
    // dependencies, remove this block and instead ensure the correct module runs
    // before bootstrap. Keeping it here prevents "not registered" crashes.
    //
    // If you cannot construct it here safely, do NOT register a dummy.
    // Prefer fail-fast: leave it unregistered and fix module ordering.
  }
}

/* -------------------------------------------------------------------------- */
/* Shared infrastructure                                                       */
/* -------------------------------------------------------------------------- */

void _registerTmdbInfrastructure() {
  if (!sl.isRegistered<TmdbImageResolver>()) {
    sl.registerLazySingleton<TmdbImageResolver>(
      () => const TmdbImageResolver(),
    );
  }

  if (!sl.isRegistered<TmdbClient>() &&
      sl.isRegistered<NetworkExecutor>() &&
      sl.isRegistered<AppConfig>()) {
    sl.registerLazySingleton<TmdbClient>(
      () => TmdbClient(
        executor: sl<NetworkExecutor>(),
        endpoints: sl<AppConfig>().network,
      ),
    );
  }

  if (!sl.isRegistered<TmdbHttpClient>() && sl.isRegistered<TmdbClient>()) {
    sl.registerLazySingleton<TmdbHttpClient>(() => sl<TmdbClient>());
  }
}

void _registerSharedServices() {
  if (!sl.isRegistered<TmdbCacheDataSource>() &&
      sl.isRegistered<ContentCacheRepository>()) {
    sl.registerLazySingleton<TmdbCacheDataSource>(
      () => TmdbCacheDataSource(sl<ContentCacheRepository>()),
    );
  }

  if (!sl.isRegistered<TmdbCacheStore>() &&
      sl.isRegistered<TmdbCacheDataSource>()) {
    sl.registerLazySingleton<TmdbCacheStore>(() => sl<TmdbCacheDataSource>());
  }

  // --------------------------------------------------------------------------
  // Parental controls: TMDB min-age cache + policy
  // --------------------------------------------------------------------------

  if (!sl.isRegistered<TmdbContentRatingRemoteDataSource>() &&
      sl.isRegistered<TmdbClient>()) {
    sl.registerLazySingleton<TmdbContentRatingRemoteDataSource>(
      () => TmdbContentRatingRemoteDataSource(sl<TmdbClient>()),
    );
  }

  if (!sl.isRegistered<ContentRatingRepository>() &&
      sl.isRegistered<TmdbContentRatingRemoteDataSource>() &&
      sl.isRegistered<ContentCacheRepository>()) {
    sl.registerLazySingleton<ContentRatingRepository>(
      () => CachedContentRatingRepository(
        sl<TmdbContentRatingRemoteDataSource>(),
        sl<ContentCacheRepository>(),
      ),
    );
  }

  if (!sl.isRegistered<AgePolicy>() && sl.isRegistered<ContentRatingRepository>()) {
    sl.registerLazySingleton<AgePolicy>(
      () => AgePolicy(sl<ContentRatingRepository>()),
    );
  }

  if (!sl.isRegistered<ParentalSessionService>() &&
      sl.isRegistered<SecureStorageRepository>()) {
    sl.registerLazySingleton<ParentalSessionService>(
      () => ParentalSessionService(sl<SecureStorageRepository>()),
    );
  }

  if (!sl.isRegistered<ProfilePinEdgeService>()) {
    sl.registerLazySingleton<ProfilePinEdgeService>(() {
      if (!sl.isRegistered<SupabaseClient>()) {
        const config = SupabaseConfig.fromEnvironment;
        if (!config.isConfigured) {
          throw StateError(
            'Supabase is not configured. Cannot register ProfilePinEdgeService.',
          );
        }
        throw StateError(
          'SupabaseClient should be registered before ProfilePinEdgeService',
        );
      }
      return ProfilePinEdgeService(sl<SupabaseClient>());
    });
  }

  if (!sl.isRegistered<PinRecoveryRemoteDataSource>()) {
    sl.registerLazySingleton<PinRecoveryRemoteDataSource>(() {
      if (!sl.isRegistered<SupabaseClient>()) {
        const config = SupabaseConfig.fromEnvironment;
        if (!config.isConfigured) {
          throw StateError(
            'Supabase is not configured. Cannot register PinRecoveryRemoteDataSource.',
          );
        }
        throw StateError(
          'SupabaseClient should be registered before PinRecoveryRemoteDataSource',
        );
      }
      return PinRecoveryRemoteDataSource(sl<SupabaseClient>());
    });
  }

  if (!sl.isRegistered<PinRecoveryRepository>()) {
    sl.registerLazySingleton<PinRecoveryRepository>(
      () {
        if (!sl.isRegistered<SupabaseClient>()) {
          const config = SupabaseConfig.fromEnvironment;
          if (!config.isConfigured) {
            throw StateError(
              'Supabase is not configured. Cannot register PinRecoveryRepository.',
            );
          }
          throw StateError(
            'SupabaseClient should be registered before PinRecoveryRepository',
          );
        }
        return PinRecoveryRepositoryImpl(
          client: sl<SupabaseClient>(),
          profilePin: sl<ProfilePinEdgeService>(),
        );
      },
    );
  }

  if (!sl.isRegistered<PlaylistMaturityClassifier>()) {
    sl.registerLazySingleton<PlaylistMaturityClassifier>(
      () => const PlaylistMaturityClassifier(),
    );
  }

  if (!sl.isRegistered<XtreamLookupService>() &&
      sl.isRegistered<IptvLocalRepository>() &&
      sl.isRegistered<AppLogger>()) {
    sl.registerLazySingleton<XtreamLookupService>(
      () => XtreamLookupService(
        iptvLocal: sl<IptvLocalRepository>(),
        logger: sl<AppLogger>(),
      ),
    );
  }

  if (!sl.isRegistered<XtreamLookup>() &&
      sl.isRegistered<XtreamLookupService>()) {
    sl.registerLazySingleton<XtreamLookup>(() => sl<XtreamLookupService>());
  }

  if (!sl.isRegistered<IptvContentResolver>() &&
      sl.isRegistered<IptvLocalRepository>() &&
      sl.isRegistered<XtreamLookupService>()) {
    sl.registerLazySingleton<IptvContentResolver>(
      () => IptvContentResolverImpl(
        iptvLocal: sl<IptvLocalRepository>(),
        lookup: sl<XtreamLookupService>(),
      ),
    );
  }

  if (!sl.isRegistered<PlaylistTmdbEnrichmentService>() &&
      sl.isRegistered<TmdbHttpClient>() &&
      sl.isRegistered<TmdbImageResolver>()) {
    sl.registerLazySingleton<PlaylistTmdbEnrichmentService>(
      () => PlaylistTmdbEnrichmentService(
        sl<TmdbHttpClient>(),
        sl<TmdbImageResolver>(),
      ),
    );
  }

  if (!sl.isRegistered<ContentEnrichmentService>() &&
      sl.isRegistered<PlaylistTmdbEnrichmentService>()) {
    sl.registerLazySingleton<ContentEnrichmentService>(
      () => sl<PlaylistTmdbEnrichmentService>(),
    );
  }

}

/* -------------------------------------------------------------------------- */
/* State & feature modules                                                     */
/* -------------------------------------------------------------------------- */

void _registerState() {
  if (sl.isRegistered<AppStateController>()) return;

  sl.registerLazySingleton<AppStateController>(() => AppStateController());
  if (!sl.isRegistered<AppLaunchStateRegistry>()) {
    sl.registerLazySingleton<AppLaunchStateRegistry>(
      () => AppLaunchStateRegistry(),
    );
  }

  // Clear TMDB in-memory cache on locale change.
  sl<LocalePreferences>().languageStream.listen((_) {
    if (sl.isRegistered<TmdbCacheDataSource>()) {
      sl<TmdbCacheDataSource>().clearMemoryMemo();
    }
  });
}

void _registerFeatureModules() {
  IptvDataModule.register();
  MovieDataModule.register();
  TvDataModule.register();
  PersonDataModule.register();
  SagaDataModule.register();
  SearchDataModule.register(); // Enregistre SimilarityService
  
  // Enregistrer TmdbIdResolverService après SearchDataModule (qui enregistre SimilarityService)
  if (!sl.isRegistered<TmdbIdResolverService>() &&
      sl.isRegistered<TmdbMovieRemoteDataSource>() &&
      sl.isRegistered<TmdbTvRemoteDataSource>() &&
      sl.isRegistered<TmdbClient>() &&
      sl.isRegistered<SimilarityService>() &&
      sl.isRegistered<AppLogger>()) {
    sl.registerLazySingleton<TmdbIdResolverService>(
      () => TmdbIdResolverService(
        moviesRemote: sl<TmdbMovieRemoteDataSource>(),
        tvRemote: sl<TmdbTvRemoteDataSource>(),
        tmdbClient: sl<TmdbClient>(),
        similarity: sl<SimilarityService>(),
        logger: sl<AppLogger>(),
      ),
    );
  }
  
  PlaylistDataModule.register();
  HomeFeedDataModule.register();
  LibraryDataModule.register();
  CategoryBrowserDataModule.register();
  SettingsDataModule.register();
}

/* -------------------------------------------------------------------------- */
/* Diagnostics                                                                 */
/* -------------------------------------------------------------------------- */

void _assertCriticalRegistrations() {
  if (!kDebugMode) return;

  final missing = <String>[];

  if (!sl.isRegistered<SupabaseClient>()) missing.add('SupabaseClient');
  if (!sl.isRegistered<SupabaseProfileRepository>()) {
    missing.add('SupabaseProfileRepository');
  }
  if (!sl.isRegistered<SupabaseIptvSourcesRepository>()) {
    missing.add('SupabaseIptvSourcesRepository');
  }
  if (!sl.isRegistered<SelectedProfilePreferences>()) {
    missing.add('SelectedProfilePreferences');
  }
  if (!sl.isRegistered<SelectedIptvSourcePreferences>()) {
    missing.add('SelectedIptvSourcePreferences');
  }
  if (!sl.isRegistered<IptvLocalRepository>()) {
    missing.add('IptvLocalRepository');
  }

  if (missing.isNotEmpty) {
    debugPrint(
      '[DI][ERROR] Missing GetIt registrations required by bootstrap: ${missing.join(", ")}',
    );
  }
}
