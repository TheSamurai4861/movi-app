import '../models/app_metadata.dart';
import '../models/feature_flags.dart';
import '../models/network_endpoints.dart';

enum AppEnvironment { dev, staging, prod }

abstract class EnvironmentFlavor {
  AppEnvironment get environment;
  String get label;
  NetworkEndpoints get network;
  FeatureFlags get defaultFlags;
  AppMetadata get metadata;

  bool get isProduction => environment == AppEnvironment.prod;
}
