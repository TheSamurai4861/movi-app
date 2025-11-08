import '../models/app_metadata.dart';
import '../models/feature_flags.dart';
import '../models/network_endpoints.dart';
import 'environment.dart';

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
  AppMetadata get metadata => const AppMetadata(
        version: '0.1.0',
        buildNumber: 'dev',
      );

  @override
  NetworkEndpoints get network => const NetworkEndpoints(
        restBaseUrl: 'https://api.dev.movi.app',
        imageBaseUrl: 'https://images.dev.movi.app',
        timeouts: NetworkTimeouts(
          connect: Duration(seconds: 5),
          receive: Duration(seconds: 10),
          send: Duration(seconds: 5),
        ),
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
  AppMetadata get metadata => const AppMetadata(
        version: '0.1.0',
        buildNumber: 'staging',
      );

  @override
  NetworkEndpoints get network => const NetworkEndpoints(
        restBaseUrl: 'https://api.staging.movi.app',
        imageBaseUrl: 'https://images.staging.movi.app',
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
  AppMetadata get metadata => const AppMetadata(
        version: '1.0.0',
        buildNumber: 'prod',
      );

  @override
  NetworkEndpoints get network => const NetworkEndpoints(
        restBaseUrl: 'https://api.movi.app',
        imageBaseUrl: 'https://images.movi.app',
        timeouts: NetworkTimeouts(
          connect: Duration(seconds: 10),
          receive: Duration(seconds: 20),
          send: Duration(seconds: 10),
        ),
      );
}
