import 'package:flutter_riverpod/misc.dart';

import 'package:movi/src/core/config/env/environment.dart';
import 'package:movi/src/core/config/models/app_config.dart';
import 'package:movi/src/core/config/models/app_metadata.dart';
import 'package:movi/src/core/config/models/feature_flags.dart';
import 'package:movi/src/core/config/models/network_endpoints.dart';
import 'package:movi/src/core/config/providers/config_provider.dart';

List<Override> createConfigOverrides(AppConfig config) {
  return [
    appConfigProvider.overrideWithValue(config),
    environmentProvider.overrideWithValue(config.environment),
    featureFlagsProvider.overrideWithValue(config.featureFlags),
    networkEndpointsProvider.overrideWithValue(config.network),
    appMetadataProvider.overrideWithValue(config.metadata),
  ];
}

Override overrideFeatureFlags(FeatureFlags flags) {
  return featureFlagsProvider.overrideWithValue(flags);
}

Override overrideEnvironment(EnvironmentFlavor flavor) {
  return environmentProvider.overrideWithValue(flavor);
}

Override overrideNetworkEndpoints(NetworkEndpoints endpoints) {
  return networkEndpointsProvider.overrideWithValue(endpoints);
}

Override overrideAppMetadata(AppMetadata metadata) {
  return appMetadataProvider.overrideWithValue(metadata);
}
