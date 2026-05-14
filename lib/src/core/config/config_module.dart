import 'package:movi/src/core/config/env/environment_loader.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';

// Imports ciblés (évite le cycle avec le barrel config.dart)
import 'package:movi/src/core/config/env/environment.dart';
import 'package:movi/src/core/config/models/app_config.dart';
import 'package:movi/src/core/config/models/app_metadata.dart';
import 'package:movi/src/core/config/models/feature_flags.dart';
import 'package:movi/src/core/config/models/logging_config.dart';
import 'package:movi/src/core/config/services/secret_store.dart';

class AppConfigFactory {
  const AppConfigFactory(this._secretStore);

  final SecretStore _secretStore;

  Future<AppConfig> build({
    required EnvironmentFlavor flavor,
    FeatureFlags? featureOverrides,
    AppMetadata? metadataOverride,
    bool requireTmdbKey = true,
  }) async {
    // Priorité au tmdbApiKey fourni par le flavor (compile-time via dart-define).
    String? tmdbKey = flavor.network.tmdbApiKey;
    if (tmdbKey == null || tmdbKey.isEmpty) {
      // Si on n'exige pas la clé au runtime, on peut tenter une résolution via SecretStore.
      if (!requireTmdbKey) {
        try {
          tmdbKey = await _secretStore.read('TMDB_API_KEY');
        } catch (_) {
          tmdbKey = null;
        }
      }
    }

    final network = flavor.network.copyWith(tmdbApiKey: tmdbKey);
    final flags = _applyFeatureFlagDefineOverrides(
      featureOverrides ?? flavor.defaultFlags,
    );
    final metadata = metadataOverride ?? flavor.metadata;
    final LoggingConfig logging = _defaultLoggingFor(flavor)..validate();

    final config = AppConfig(
      environment: flavor,
      network: network,
      featureFlags: flags,
      metadata: metadata,
      logging: logging,
      requireTmdbKey: requireTmdbKey,
    );

    config.ensureValid();
    return config;
  }
}

FeatureFlags _applyFeatureFlagDefineOverrides(FeatureFlags base) {
  const diskCacheRaw = String.fromEnvironment('IMAGES_ENABLE_DISK_CACHE');
  const cachedPathRaw = String.fromEnvironment(
    'IMAGES_ENABLE_CACHED_NETWORK_PATH',
  );
  const fallbackOnlyRaw = String.fromEnvironment(
    'IMAGES_FORCE_NETWORK_FALLBACK_ONLY',
  );

  bool? parseNullableBool(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    if (normalized == '1' || normalized == 'true') return true;
    if (normalized == '0' || normalized == 'false') return false;
    return null;
  }

  final diskCache = parseNullableBool(diskCacheRaw);
  final cachedPath = parseNullableBool(cachedPathRaw);
  final fallbackOnly = parseNullableBool(fallbackOnlyRaw);

  return base.copyWith(
    enableImageDiskCache: diskCache ?? base.enableImageDiskCache,
    enableImageCachedNetworkPath:
        cachedPath ?? base.enableImageCachedNetworkPath,
    forceImageNetworkFallbackOnly:
        fallbackOnly ?? base.forceImageNetworkFallbackOnly,
  );
}

Future<AppConfig> loadAppConfig({
  required EnvironmentFlavor flavor,
  SecretStore? secretStore,
  FeatureFlags? featureOverrides,
  AppMetadata? metadataOverride,
  bool requireTmdbKey = true,
}) async {
  final store = secretStore ?? SecretStore();
  final factory = AppConfigFactory(store);
  return factory.build(
    flavor: flavor,
    featureOverrides: featureOverrides,
    metadataOverride: metadataOverride,
    requireTmdbKey: requireTmdbKey,
  );
}

Future<AppConfig> registerConfig({
  required EnvironmentFlavor flavor,
  SecretStore? secretStore,
  FeatureFlags? featureOverrides,
  AppMetadata? metadataOverride,
  bool requireTmdbKey = true,
  bool registerWithLocator = true,
}) async {
  final store = secretStore ?? SecretStore();
  if (registerWithLocator) {
    _replace<SecretStore>(store);
  }

  final config = await loadAppConfig(
    flavor: flavor,
    secretStore: store,
    featureOverrides: featureOverrides,
    metadataOverride: metadataOverride,
    requireTmdbKey: requireTmdbKey,
  );

  if (registerWithLocator) {
    _replace<EnvironmentFlavor>(flavor);
    _replace<AppConfig>(config);
    _replace<FeatureFlags>(config.featureFlags);
  }

  return config;
}

void _replace<T extends Object>(T instance) {
  if (sl.isRegistered<T>()) {
    sl.unregister<T>();
  }
  sl.registerSingleton<T>(instance);
}

void registerEnvironmentLoader(EnvironmentLoader loader) {
  _replace<EnvironmentLoader>(loader);
}

LoggingConfig _defaultLoggingFor(EnvironmentFlavor flavor) {
  switch (flavor.environment) {
    case AppEnvironment.dev:
      return const LoggingConfig(
        minLevel: LogLevel.debug,
        enableConsole: true,
        enableFile: true,
        samplingByLevel: {LogLevel.debug: 1.0},
        samplingByCategory: {'home_hero_debug': 0.2, 'image_pipeline': 0.25},
        rateLimitPerCategory: {
          'home_hero_debug': 120,
          'image_pipeline': 180,
          'startup_contract': 600,
        },
        minLevelByCategory: {'startup_contract': LogLevel.info},
        defaultRateLimitPerMinute: 0,
        exposeMetrics: true,
      );
    case AppEnvironment.staging:
      return const LoggingConfig(
        minLevel: LogLevel.info,
        enableConsole: false,
        enableFile: true,
        samplingByLevel: {LogLevel.debug: 0.5},
        samplingByCategory: {'home_hero_debug': 0.05, 'image_pipeline': 0.1},
        rateLimitPerCategory: {
          'home_hero_debug': 20,
          'image_pipeline': 60,
          'startup_contract': 300,
        },
        minLevelByCategory: {
          'home_hero_debug': LogLevel.warn,
          'image_pipeline': LogLevel.warn,
          'startup_contract': LogLevel.info,
        },
        defaultRateLimitPerMinute: 200,
        exposeMetrics: true,
      );
    case AppEnvironment.prod:
      return const LoggingConfig(
        minLevel: LogLevel.warn,
        enableConsole: false,
        enableFile: true,
        samplingByLevel: {LogLevel.debug: 0.1},
        samplingByCategory: {'home_hero_debug': 0.0, 'image_pipeline': 0.05},
        rateLimitPerCategory: {
          'home_hero_debug': 5,
          'image_pipeline': 30,
          'startup_contract': 200,
        },
        minLevelByCategory: {
          'home_hero_debug': LogLevel.warn,
          'image_pipeline': LogLevel.warn,
          'startup_contract': LogLevel.info,
        },
        defaultRateLimitPerMinute: 100,
        exposeMetrics: true,
      );
  }
}
