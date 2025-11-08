import '../env/environment.dart';
import 'app_metadata.dart';
import 'feature_flags.dart';
import 'network_endpoints.dart';

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.network,
    required this.featureFlags,
    required this.metadata,
  });

  final EnvironmentFlavor environment;
  final NetworkEndpoints network;
  final FeatureFlags featureFlags;
  final AppMetadata metadata;

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
}
