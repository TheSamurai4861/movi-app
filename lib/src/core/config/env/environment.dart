import 'package:movi/src/core/config/models/app_metadata.dart';
import 'package:movi/src/core/config/models/feature_flags.dart';
import 'package:movi/src/core/config/models/network_endpoints.dart';

enum AppEnvironment { dev, staging, prod }

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
}
