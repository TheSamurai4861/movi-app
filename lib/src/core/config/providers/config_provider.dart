import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/config/config.dart';

final appConfigProvider = Provider<AppConfig>((ref) => sl<AppConfig>());

final environmentProvider = Provider<EnvironmentFlavor>(
  (ref) => sl<EnvironmentFlavor>(),
);

final featureFlagsProvider = Provider<FeatureFlags>(
  (ref) => ref.watch(appConfigProvider).featureFlags,
);

final networkEndpointsProvider = Provider<NetworkEndpoints>(
  (ref) => ref.watch(appConfigProvider).network,
);

final appMetadataProvider = Provider<AppMetadata>(
  (ref) => ref.watch(appConfigProvider).metadata,
);
