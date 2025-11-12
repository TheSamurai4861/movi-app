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
}
