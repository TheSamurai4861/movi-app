// ignore_for_file: public_member_api_docs

import 'package:movi/src/core/config/models/app_metadata.dart';
import 'package:movi/src/core/config/models/feature_flags.dart';
import 'package:movi/src/core/config/models/network_endpoints.dart';
import 'package:movi/src/core/config/env/environment.dart';

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

EnvironmentFlavor createDevEnvironment() {
  final env = AppEnvironment.dev;
  return EnvironmentFlavor(
    environment: env,
    label: 'Development',
    defaultFlags: const FeatureFlags(
      useRemoteHome: false,
      enableTelemetry: true,
      enableDownloads: false,
      enableNewSearch: true,
    ),
    metadata: const AppMetadata(version: '0.1.0', buildNumber: 'dev'),
    network: NetworkEndpoints(
      restBaseUrl: 'https://api.dev.movi.app',
      imageBaseUrl: 'https://images.dev.movi.app',
      tmdbApiKey: _resolveTmdbKey(env),
      timeouts: _defaultTimeouts,
    ),
  );
}

EnvironmentFlavor createStagingEnvironment() {
  final env = AppEnvironment.staging;
  return EnvironmentFlavor(
    environment: env,
    label: 'Staging',
    defaultFlags: const FeatureFlags(
      useRemoteHome: true,
      enableTelemetry: true,
      enableDownloads: true,
      enableNewSearch: true,
    ),
    metadata: const AppMetadata(version: '0.1.0', buildNumber: 'staging'),
    network: NetworkEndpoints(
      restBaseUrl: 'https://api.staging.movi.app',
      imageBaseUrl: 'https://images.staging.movi.app',
      tmdbApiKey: _resolveTmdbKey(env),
      timeouts: _defaultTimeouts,
    ),
  );
}

EnvironmentFlavor createProdEnvironment() {
  final env = AppEnvironment.prod;
  return EnvironmentFlavor(
    environment: env,
    label: 'Production',
    defaultFlags: const FeatureFlags(
      useRemoteHome: true,
      enableTelemetry: true,
      enableDownloads: true,
      enableNewSearch: true,
    ),
    metadata: const AppMetadata(version: '1.0.0', buildNumber: 'prod'),
    network: NetworkEndpoints(
      restBaseUrl: 'https://api.movi.app',
      imageBaseUrl: 'https://images.movi.app',
      tmdbApiKey: _resolveTmdbKey(env),
      timeouts: const NetworkTimeouts(
        connect: Duration(seconds: 10),
        receive: Duration(seconds: 20),
        send: Duration(seconds: 10),
      ),
    ),
  );
}
