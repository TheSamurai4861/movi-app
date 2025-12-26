// ignore_for_file: public_member_api_docs

import 'package:movi/src/core/config/models/app_metadata.dart';
import 'package:movi/src/core/config/models/feature_flags.dart';
import 'package:movi/src/core/config/models/network_endpoints.dart';
import 'package:movi/src/core/config/env/environment.dart';

/// Compile-time configuration for TMDB access.
///
/// Values are provided via `--dart-define` at build/run time.
/// Priority order:
/// 1. generic key: TMDB_API_KEY
/// 2. flavor-specific key: TMDB_API_KEY_DEV / _STAGING / _PROD
const String _tmdbApiKeyGeneric = String.fromEnvironment('TMDB_API_KEY');
const String _tmdbApiKeyDev = String.fromEnvironment('TMDB_API_KEY_DEV');
const String _tmdbApiKeyStaging = String.fromEnvironment(
  'TMDB_API_KEY_STAGING',
);
const String _tmdbApiKeyProd = String.fromEnvironment('TMDB_API_KEY_PROD');

/// Resolve the TMDB API key for a given [AppEnvironment].
///
/// If no key is provided via `--dart-define`, this returns `null`
/// and lets the caller decide how to resolve a key at runtime
/// (e.g. from a secure storage, .env, etc.).
String? _resolveTmdbKey(AppEnvironment env) {
  // First, try the generic key if present.
  String candidate = _tmdbApiKeyGeneric;

  // If not set, fallback to environment-specific key.
  if (candidate.isEmpty) {
    switch (env) {
      case AppEnvironment.dev:
        candidate = _tmdbApiKeyDev;
        break;
      case AppEnvironment.staging:
        candidate = _tmdbApiKeyStaging;
        break;
      case AppEnvironment.prod:
        candidate = _tmdbApiKeyProd;
        break;
    }
  }

  // Normalize empty strings to null so callers can detect "no key".
  return candidate.isNotEmpty ? candidate : null;
}

/// Default network timeouts used across flavors when not overridden.
const NetworkTimeouts _defaultTimeouts = NetworkTimeouts(
  connect: Duration(seconds: 15),
  receive: Duration(seconds: 40),
  send: Duration(seconds: 15),
);

/// Build the Development environment flavor.
EnvironmentFlavor createDevEnvironment() => _buildFlavor(
  env: AppEnvironment.dev,
  label: 'Development',
  flags: const FeatureFlags(
    useRemoteHome: false,
    disableHomeHero: false,
    enableTelemetry: true,
    enableDownloads: false,
    enableNewSearch: true,
  ),
  metadata: const AppMetadata(version: '0.1.0', buildNumber: 'dev'),
  restBaseUrl: 'https://api.dev.movi.app',
  imageBaseUrl: 'https://images.dev.movi.app',
  timeouts: _defaultTimeouts,
);

/// Build the Staging environment flavor.
EnvironmentFlavor createStagingEnvironment() => _buildFlavor(
  env: AppEnvironment.staging,
  label: 'Staging',
  flags: const FeatureFlags(
    useRemoteHome: true,
    enableTelemetry: true,
    enableDownloads: true,
    enableNewSearch: true,
  ),
  metadata: const AppMetadata(version: '0.1.0', buildNumber: 'staging'),
  restBaseUrl: 'https://api.staging.movi.app',
  imageBaseUrl: 'https://images.staging.movi.app',
  timeouts: _defaultTimeouts,
);

/// Build the Production environment flavor.
EnvironmentFlavor createProdEnvironment() => _buildFlavor(
  env: AppEnvironment.prod,
  label: 'Production',
  flags: const FeatureFlags(
    useRemoteHome: true,
    enableTelemetry: true,
    enableDownloads: true,
    enableNewSearch: true,
  ),
  metadata: const AppMetadata(version: '1.0.0', buildNumber: 'prod'),
  restBaseUrl: 'https://api.movi.app',
  imageBaseUrl: 'https://images.movi.app',
  timeouts: const NetworkTimeouts(
    connect: Duration(seconds: 10),
    receive: Duration(seconds: 45),
    send: Duration(seconds: 10),
  ),
);

/// Internal helper to build a fully configured [EnvironmentFlavor].
EnvironmentFlavor _buildFlavor({
  required AppEnvironment env,
  required String label,
  required FeatureFlags flags,
  required AppMetadata metadata,
  required String restBaseUrl,
  required String imageBaseUrl,
  NetworkTimeouts timeouts = const NetworkTimeouts(),
}) {
  return EnvironmentFlavor(
    environment: env,
    label: label,
    defaultFlags: flags,
    metadata: metadata,
    network: NetworkEndpoints(
      restBaseUrl: restBaseUrl,
      imageBaseUrl: imageBaseUrl,
      tmdbApiKey: _resolveTmdbKey(env),
      timeouts: timeouts,
    ),
  );
}
