import 'package:flutter_riverpod/misc.dart';

import '../env/environment.dart';
import '../models/app_config.dart';
import '../models/feature_flags.dart';
import 'config_provider.dart';

List<Override> createConfigOverrides(AppConfig config) {
  return [
    appConfigProvider.overrideWithValue(config),
    environmentProvider.overrideWithValue(config.environment),
    featureFlagsProvider.overrideWithValue(config.featureFlags),
  ];
}

Override overrideFeatureFlags(FeatureFlags flags) {
  return featureFlagsProvider.overrideWithValue(flags);
}

Override overrideEnvironment(EnvironmentFlavor flavor) {
  return environmentProvider.overrideWithValue(flavor);
}
