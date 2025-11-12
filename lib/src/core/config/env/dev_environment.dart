// ignore_for_file: public_member_api_docs

import '../models/app_metadata.dart';
import '../models/feature_flags.dart';
import '../models/network_endpoints.dart';
import 'environment.dart';

/// Compile-time configuration for TMDB access.
/// Provide with `--dart-define` at build/run time.
/// Priority order: generic > flavor-specific.
const String _tmdbApiKeyGeneric = String.fromEnvironment('TMDB_API_KEY');
const String _tmdbApiKeyDev = String.fromEnvironment('TMDB_API_KEY_DEV');
const String _tmdbApiKeyStaging = String.fromEnvironment(
  'TMDB_API_KEY_STAGING',
);
const String _tmdbApiKeyProd = String.fromEnvironment('TMDB_API_KEY_PROD');

/// Fallback explicite pour le flavor Dev (usage local uniquement).
/// ATTENTION: ne pas utiliser en prod/staging. Cette valeur sera intégrée au binaire.
const String _tmdbHardcodedKeyDev =
    'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI0ZjliZDI0YzhiMjYyNWUyMzk2ZTNlZjg2YTg5ZmU0YyIsIm5iZiI6MTY0ODM4MzU1My4yNDEsInN1YiI6IjYyNDA1NjQxYzc0MGQ5MDA0N2EzNmNjMyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.KvWRTSdQiWBF2-KQhgN_7xzSJS8AS7xE3-A7fzxCno8';

/// Optionally returns the TMDB API key from compile-time defines.
/// If no key is provided via --dart-define, returns null to allow
/// runtime resolution (e.g., via .env or process environment).
String? _resolveTmdbKey(AppEnvironment env) {
  String candidate;
  switch (env) {
    case AppEnvironment.dev:
      candidate = _tmdbApiKeyDev.isNotEmpty
          ? _tmdbApiKeyDev
          : _tmdbApiKeyGeneric;
      break;
    case AppEnvironment.staging:
      candidate = _tmdbApiKeyStaging.isNotEmpty
          ? _tmdbApiKeyStaging
          : _tmdbApiKeyGeneric;
      break;
    case AppEnvironment.prod:
      candidate = _tmdbApiKeyProd.isNotEmpty
          ? _tmdbApiKeyProd
          : _tmdbApiKeyGeneric;
      break;
  }
  return candidate.isNotEmpty ? candidate : null;
}

/// Default network timeouts used across flavors when not overridden.
const NetworkTimeouts _defaultTimeouts = NetworkTimeouts(
  connect: Duration(seconds: 5),
  receive: Duration(seconds: 10),
  send: Duration(seconds: 5),
);

class DevEnvironment implements EnvironmentFlavor {
  @override
  AppEnvironment get environment => AppEnvironment.dev;

  @override
  String get label => 'Development';

  @override
  bool get isProduction => false;

  @override
  FeatureFlags get defaultFlags => const FeatureFlags(
    useRemoteHome: false,
    enableTelemetry: true,
    enableDownloads: false,
    enableNewSearch: true,
  );

  @override
  AppMetadata get metadata =>
      const AppMetadata(version: '0.1.0', buildNumber: 'dev');

  @override
  NetworkEndpoints get network => NetworkEndpoints(
    restBaseUrl: 'https://api.dev.movi.app',
    imageBaseUrl: 'https://images.dev.movi.app',

    /// TMDB key may be provided via dart-define or deferred to SecretStore (.env).
    /// Fallback local: clé intégrée en dur pour le flavor Dev uniquement.
    tmdbApiKey: _resolveTmdbKey(environment) ?? _tmdbHardcodedKeyDev,
    timeouts: _defaultTimeouts,
  );
}

class StagingEnvironment implements EnvironmentFlavor {
  @override
  AppEnvironment get environment => AppEnvironment.staging;

  @override
  String get label => 'Staging';

  @override
  bool get isProduction => false;

  @override
  FeatureFlags get defaultFlags => const FeatureFlags(
    useRemoteHome: true,
    enableTelemetry: true,
    enableDownloads: true,
    enableNewSearch: true,
  );

  @override
  AppMetadata get metadata =>
      const AppMetadata(version: '0.1.0', buildNumber: 'staging');

  @override
  NetworkEndpoints get network => NetworkEndpoints(
    restBaseUrl: 'https://api.staging.movi.app',
    imageBaseUrl: 'https://images.staging.movi.app',
    tmdbApiKey: _resolveTmdbKey(environment),
    timeouts: _defaultTimeouts,
  );
}

class ProdEnvironment implements EnvironmentFlavor {
  @override
  AppEnvironment get environment => AppEnvironment.prod;

  @override
  String get label => 'Production';

  @override
  bool get isProduction => true;

  @override
  FeatureFlags get defaultFlags => const FeatureFlags(
    useRemoteHome: true,
    enableTelemetry: true,
    enableDownloads: true,
    enableNewSearch: true,
  );

  @override
  AppMetadata get metadata =>
      const AppMetadata(version: '1.0.0', buildNumber: 'prod');

  @override
  NetworkEndpoints get network => NetworkEndpoints(
    restBaseUrl: 'https://api.movi.app',
    imageBaseUrl: 'https://images.movi.app',
    tmdbApiKey: _resolveTmdbKey(environment),
    timeouts: const NetworkTimeouts(
      connect: Duration(seconds: 10),
      receive: Duration(seconds: 20),
      send: Duration(seconds: 10),
    ),
  );
}
