// ignore_for_file: public_member_api_docs

import '../env/environment.dart';
import 'app_metadata.dart';
import 'feature_flags.dart';
import 'network_endpoints.dart';

/// Immutable application configuration assembled at bootstrap.
/// Contains the current environment, network endpoints (incl. TMDB),
/// feature flags and application metadata. No I/O is performed here.
class AppConfig {
  AppConfig({
    required this.environment,
    required this.network,
    required this.featureFlags,
    required this.metadata,
  }) : assert(
         (network.restBaseUrl.isNotEmpty),
         'restBaseUrl must not be empty.',
       ),
       assert(
         (network.imageBaseUrl.isNotEmpty),
         'imageBaseUrl must not be empty.',
       ),
       // Fail fast in debug/profile if the TMDB key is missing.
       // Network clients must still validate at runtime and surface clear errors.
       assert(
         (network.tmdbApiKey?.isNotEmpty ?? false),
         'tmdbApiKey must not be empty. Provide it via your flavor/environment.',
       );

  /// Current runtime environment/flavor (dev, staging, prod).
  final EnvironmentFlavor environment;

  /// Network endpoints and API keys (including TMDB).
  final NetworkEndpoints network;

  /// Feature toggles enabled for this build.
  final FeatureFlags featureFlags;

  /// App metadata (version/build).
  final AppMetadata metadata;

  /// Lightweight validity check intended for runtime guards in release builds.
  /// Throws [StateError] with an explicit message when a critical value is invalid.
  void ensureValid() {
    if ((network.restBaseUrl).isEmpty) {
      throw StateError('AppConfig.network.restBaseUrl is empty.');
    }
    if ((network.imageBaseUrl).isEmpty) {
      throw StateError('AppConfig.network.imageBaseUrl is empty.');
    }
    if ((network.tmdbApiKey ?? '').isEmpty) {
      throw StateError(
        'AppConfig.network.tmdbApiKey is empty. '
        'Ensure your flavor/environment provides a valid TMDB key.',
      );
    }
  }

  /// Returns a copy of this configuration with selectively replaced fields.
  AppConfig copyWith({
    EnvironmentFlavor? environment,
    NetworkEndpoints? network,
    FeatureFlags? featureFlags,
    AppMetadata? metadata,
  }) {
    return AppConfig(
      environment: environment ?? this.environment,
      network: network ?? this.network,
      featureFlags: featureFlags ?? this.featureFlags,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convenience booleans for quick checks without leaking environment internals.
  bool get isProduction => environment.isProduction;

  /// True when a (non-empty) TMDB key is present from the active flavor.
  bool get hasTmdbKey => (network.tmdbApiKey?.isNotEmpty ?? false);

  @override
  String toString() {
    // Do not print secrets.
    final key = network.tmdbApiKey ?? '';
    final maskedKey = key.isEmpty ? '<empty>' : '***${key.hashCode}';
    return 'AppConfig(env: ${environment.label}, '
        'rest: ${network.restBaseUrl}, images: ${network.imageBaseUrl}, '
        'tmdbKey: $maskedKey, flags: $featureFlags, meta: $metadata)';
  }
}
