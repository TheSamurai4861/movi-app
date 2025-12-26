// ignore_for_file: public_member_api_docs

import 'package:flutter/foundation.dart';
import 'package:movi/src/core/config/models/app_metadata.dart';
import 'package:movi/src/core/config/models/feature_flags.dart';
import 'package:movi/src/core/config/models/network_endpoints.dart';

/// Supported application environments / flavors.
enum AppEnvironment {
  dev,
  staging,
  prod,
}

/// Immutable description of a given environment flavor.
///
/// Grouped here:
/// - [environment]: dev/staging/prod
/// - [label]: a human-readable label (for logs, debug screens, etc.)
/// - [network]: base URLs, timeouts, TMDB key...
/// - [defaultFlags]: feature flags used as defaults
/// - [metadata]: version, build number...
@immutable
class EnvironmentFlavor {
  const EnvironmentFlavor({
    required this.environment,
    required this.label,
    required this.network,
    required this.defaultFlags,
    required this.metadata,
  });

  final AppEnvironment environment;
  final String label;
  final NetworkEndpoints network;
  final FeatureFlags defaultFlags;
  final AppMetadata metadata;

  /// Convenience getter to know if this flavor represents Production.
  bool get isProduction => environment == AppEnvironment.prod;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EnvironmentFlavor) return false;
    return environment == other.environment &&
        label == other.label &&
        network == other.network &&
        defaultFlags == other.defaultFlags &&
        metadata == other.metadata;
  }

  @override
  int get hashCode =>
      Object.hash(environment, label, network, defaultFlags, metadata);

  @override
  String toString() {
    return 'EnvironmentFlavor('
        'environment: $environment, '
        'label: $label, '
        'network: $network, '
        'defaultFlags: $defaultFlags, '
        'metadata: $metadata'
        ')';
  }
}
