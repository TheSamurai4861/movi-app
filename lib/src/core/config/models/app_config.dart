// ignore_for_file: public_member_api_docs

import 'package:movi/src/core/config/env/environment.dart';
import 'package:movi/src/core/config/models/app_metadata.dart';
import 'package:movi/src/core/config/models/feature_flags.dart';
import 'package:movi/src/core/config/models/logging_config.dart';
import 'package:movi/src/core/config/models/network_endpoints.dart';

/// Immutable application configuration assembled at bootstrap.
/// Contains the current environment, network endpoints (incl. TMDB),
/// feature flags and application metadata. No I/O is performed here.
class AppConfig {
  AppConfig({
    required this.environment,
    required this.network,
    required this.featureFlags,
    required this.metadata,
    required this.logging,
    this.requireTmdbKey = true,
  }) : assert(
         (network.restBaseUrl.isNotEmpty),
         'restBaseUrl must not be empty.',
       ),
       assert(
         (network.imageBaseUrl.isNotEmpty),
         'imageBaseUrl must not be empty.',
       ),
       // Fail fast in debug/profile if the TMDB key is missing unless opt-out.
       // Network clients must still validate at runtime and surface clear errors.
       assert(
         !requireTmdbKey || (network.tmdbApiKey?.isNotEmpty ?? false),
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

  /// Logging configuration for the current environment.
  final LoggingConfig logging;

  /// Whether [ensureValid] must enforce the presence of a TMDB key.
  final bool requireTmdbKey;

  /// Lightweight validity check intended for runtime guards in release builds.
  /// Throws [StateError] with an explicit message when a critical value is invalid.
  void ensureValid() {
    if ((network.restBaseUrl).isEmpty) {
      throw StateError('AppConfig.network.restBaseUrl is empty.');
    }
    if ((network.imageBaseUrl).isEmpty) {
      throw StateError('AppConfig.network.imageBaseUrl is empty.');
    }
    if (requireTmdbKey && (network.tmdbApiKey ?? '').isEmpty) {
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
    LoggingConfig? logging,
    bool? requireTmdbKey,
  }) {
    return AppConfig(
      environment: environment ?? this.environment,
      network: network ?? this.network,
      featureFlags: featureFlags ?? this.featureFlags,
      metadata: metadata ?? this.metadata,
      logging: logging ?? this.logging,
      requireTmdbKey: requireTmdbKey ?? this.requireTmdbKey,
    );
  }

  /// Convenience booleans for quick checks without leaking environment internals.
  bool get isProduction => environment.isProduction;

  /// True when a (non-empty) TMDB key is present from the active flavor.
  bool get hasTmdbKey => (network.tmdbApiKey?.isNotEmpty ?? false);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AppConfig) return false;
    return environment.environment == other.environment.environment &&
        environment.label == other.environment.label &&
        network.restBaseUrl == other.network.restBaseUrl &&
        network.imageBaseUrl == other.network.imageBaseUrl &&
        (network.tmdbApiKey ?? '') == (other.network.tmdbApiKey ?? '') &&
        network.resolvedTmdbBaseHost == other.network.resolvedTmdbBaseHost &&
        network.resolvedTmdbApiVersion ==
            other.network.resolvedTmdbApiVersion &&
        network.timeouts.connect == other.network.timeouts.connect &&
        network.timeouts.receive == other.network.timeouts.receive &&
        network.timeouts.send == other.network.timeouts.send &&
        featureFlags.useRemoteHome == other.featureFlags.useRemoteHome &&
        featureFlags.disableHomeHero == other.featureFlags.disableHomeHero &&
        featureFlags.enableTelemetry == other.featureFlags.enableTelemetry &&
        featureFlags.enableDownloads == other.featureFlags.enableDownloads &&
        featureFlags.enableNewSearch == other.featureFlags.enableNewSearch &&
        metadata.version == other.metadata.version &&
        metadata.buildNumber == other.metadata.buildNumber &&
        metadata.supportEmail == other.metadata.supportEmail &&
        logging.minLevel == other.logging.minLevel &&
        logging.enableConsole == other.logging.enableConsole &&
        logging.enableFile == other.logging.enableFile &&
        logging.flushInterval == other.logging.flushInterval &&
        logging.maxFileSizeBytes == other.logging.maxFileSizeBytes &&
        logging.maxFiles == other.logging.maxFiles &&
        logging.rotateDaily == other.logging.rotateDaily &&
        logging.maxDailyFiles == other.logging.maxDailyFiles &&
        logging.compressOld == other.logging.compressOld &&
        logging.bufferCapacity == other.logging.bufferCapacity &&
        logging.dropOldest == other.logging.dropOldest &&
        _mapEquals(logging.samplingByLevel, other.logging.samplingByLevel) &&
        _stringIntMapEquals(
          logging.rateLimitPerCategory,
          other.logging.rateLimitPerCategory,
        ) &&
        _stringDoubleMapEquals(
          logging.samplingByCategory,
          other.logging.samplingByCategory,
        ) &&
        logging.defaultRateLimitPerMinute ==
            other.logging.defaultRateLimitPerMinute &&
        logging.exposeMetrics == other.logging.exposeMetrics &&
        logging.metricsInterval == other.logging.metricsInterval &&
        requireTmdbKey == other.requireTmdbKey;
  }

  @override
  int get hashCode => Object.hashAll([
    environment.environment,
    environment.label,
    network.restBaseUrl,
    network.imageBaseUrl,
    network.tmdbApiKey ?? '',
    network.resolvedTmdbBaseHost,
    network.resolvedTmdbApiVersion,
    network.timeouts.connect,
    network.timeouts.receive,
    network.timeouts.send,
    featureFlags.useRemoteHome,
    featureFlags.disableHomeHero,
    featureFlags.enableTelemetry,
    featureFlags.enableDownloads,
    featureFlags.enableNewSearch,
    metadata.version,
    metadata.buildNumber,
    metadata.supportEmail,
    logging.minLevel,
    logging.enableConsole,
    logging.enableFile,
    logging.flushInterval,
    logging.maxFileSizeBytes,
    logging.maxFiles,
    logging.rotateDaily,
    logging.maxDailyFiles,
    logging.compressOld,
    logging.bufferCapacity,
    logging.dropOldest,
    logging.defaultRateLimitPerMinute,
    logging.exposeMetrics,
    logging.metricsInterval,
    _mapHash(logging.samplingByLevel),
    _mapHash(logging.samplingByCategory),
    _mapHash(logging.rateLimitPerCategory),
    _mapHash(logging.minLevelByCategory),
    requireTmdbKey,
  ]);

  @override
  String toString() {
    // Do not print secrets.
    final key = network.tmdbApiKey ?? '';
    final maskedKey = key.isEmpty ? '<empty>' : '***${key.hashCode}';
    return 'AppConfig(env: ${environment.label}, '
        'rest: ${network.restBaseUrl}, images: ${network.imageBaseUrl}, '
        'tmdbKey: $maskedKey, flags: $featureFlags, meta: $metadata, logging: $logging)';
  }

  bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

  bool _stringIntMapEquals(Map<String, int> a, Map<String, int> b) =>
      _mapEquals<String, int>(a, b);
  bool _stringDoubleMapEquals(Map<String, double> a, Map<String, double> b) =>
      _mapEquals<String, double>(a, b);

  int _mapHash<K, V>(Map<K, V> map) => Object.hashAll(
    map.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}
