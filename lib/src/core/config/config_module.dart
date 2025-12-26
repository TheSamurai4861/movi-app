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
    final flags = featureOverrides ?? flavor.defaultFlags;
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
        defaultRateLimitPerMinute: 0,
        exposeMetrics: true,
      );
    case AppEnvironment.staging:
      return const LoggingConfig(
        minLevel: LogLevel.info,
        enableConsole: false,
        enableFile: true,
        samplingByLevel: {LogLevel.debug: 0.5},
        defaultRateLimitPerMinute: 200,
        exposeMetrics: true,
      );
    case AppEnvironment.prod:
      return const LoggingConfig(
        minLevel: LogLevel.warn,
        enableConsole: false,
        enableFile: true,
        samplingByLevel: {LogLevel.debug: 0.1},
        defaultRateLimitPerMinute: 100,
        exposeMetrics: true,
      );
  }
}
