import 'package:get_it/get_it.dart';

import 'package:movi/src/core/config/config.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/logging/logging_module.dart';
import 'package:movi/src/core/network/config/network_module.dart';
import 'package:movi/src/core/network/network.dart';
import 'package:movi/src/core/preferences/preferences.dart';
import 'package:movi/src/core/state/state.dart';
import 'package:movi/src/core/storage/services/storage_module.dart';
import 'package:movi/src/features/category_browser/data/category_browser_data_module.dart';
import 'package:movi/src/features/home/data/home_feed_data_module.dart';
import 'package:movi/src/features/iptv/data/iptv_data_module.dart';
import 'package:movi/src/features/library/data/library_data_module.dart';
import 'package:movi/src/features/movie/data/movie_data_module.dart';
import 'package:movi/src/features/person/data/person_data_module.dart';
import 'package:movi/src/features/playlist/data/playlist_data_module.dart';
import 'package:movi/src/features/saga/data/saga_data_module.dart';
import 'package:movi/src/features/search/data/search_data_module.dart';
import 'package:movi/src/features/settings/data/settings_data_module.dart';
import 'package:movi/src/features/tv/data/tv_data_module.dart';
import 'package:movi/src/shared/services.dart';

/// Global service locator instance used across the app.
final sl = GetIt.instance;

void _replace<T extends Object>(T instance) {
  if (sl.isRegistered<T>()) {
    sl.unregister<T>();
  }
  sl.registerSingleton<T>(instance);
}

void replace<T extends Object>(T instance) => _replace<T>(instance);

Future<void> initDependencies({
  AppConfig? appConfig,
  SecretStore? secretStore,
  LocaleCodeProvider? localeProvider,
  bool registerFeatureModules = true,
}) async {
  await _ensureConfig(appConfig);
  _ensureSecretStore(secretStore);
  await _ensureLocalePreferences();
  _registerLoggingIfReady();
  await StorageModule.register();
  await _registerNetwork(localeProvider: localeProvider);
  _registerTmdbInfrastructure();
  if (registerFeatureModules) {
    _registerFeatureModules();
  }
  _registerState();
}

Future<void> _ensureConfig(AppConfig? config) async {
  if (config == null) return;
  if (sl.isRegistered<AppLogger>()) {
    await LoggingModule.dispose();
  }
  _replace<AppConfig>(config);
}

void _ensureSecretStore(SecretStore? store) {
  if (store != null) {
    _replace<SecretStore>(store);
  } else if (!sl.isRegistered<SecretStore>()) {
    sl.registerLazySingleton<SecretStore>(() => SecretStore());
  }
}

Future<void> _ensureLocalePreferences() async {
  if (sl.isRegistered<LocalePreferences>()) return;
  final prefs = await LocalePreferences.create();
  sl.registerSingleton<LocalePreferences>(prefs);
}

void _registerLoggingIfReady() {
  if (sl.isRegistered<AppConfig>()) {
    LoggingModule.register();
  }
}

Future<void> _registerNetwork({LocaleCodeProvider? localeProvider}) async {
  if (!sl.isRegistered<AppConfig>()) return;
  NetworkModule.register(localeProvider: localeProvider);
}

void _registerTmdbInfrastructure() {
  if (!sl.isRegistered<TmdbImageResolver>()) {
    sl.registerLazySingleton<TmdbImageResolver>(
      () => const TmdbImageResolver(),
    );
  }

  // Si déjà enregistré, ne rien faire.
  if (sl.isRegistered<TmdbClient>()) return;

  // On ne peut pas créer TmdbClient si les dépendances ne sont pas prêtes.
  if (!sl.isRegistered<NetworkExecutor>() || !sl.isRegistered<AppConfig>()) {
    return;
  }

  // TmdbClient attend des paramètres NOMMÉS :
  // TmdbClient({ required NetworkExecutor executor, required NetworkEndpoints endpoints })
  sl.registerLazySingleton<TmdbClient>(
    () => TmdbClient(
      executor: sl<NetworkExecutor>(),
      endpoints: sl<AppConfig>().network,
    ),
  );
}

void _registerFeatureModules() {
  IptvDataModule.register();
  MovieDataModule.register();
  TvDataModule.register();
  PersonDataModule.register();
  SagaDataModule.register();
  SearchDataModule.register();
  PlaylistDataModule.register();
  HomeFeedDataModule.register();
  LibraryDataModule.register();
  CategoryBrowserDataModule.register();
  SettingsDataModule.register();
}

void _registerState() {
  if (!sl.isRegistered<AppStateController>()) {
    sl.registerLazySingleton<AppStateController>(
      () => AppStateController(sl<LocalePreferences>()),
    );
    // Attach listeners explicitly (no side-effects in constructor)
    sl<AppStateController>().attachLocaleStream();
  }
}
