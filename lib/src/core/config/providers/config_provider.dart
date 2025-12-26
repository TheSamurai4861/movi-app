import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/config/config.dart';

final _appConfigFallbackProvider = Provider<AppConfig?>((ref) {
  final locator = ref.watch(slProvider);
  if (locator.isRegistered<AppConfig>()) {
    return locator<AppConfig>();
  }
  return null;
});

final appConfigProvider = Provider<AppConfig>((ref) {
  final config = ref.watch(_appConfigFallbackProvider);
  if (config != null) return config;

  throw StateError(
    'AppConfig not provided. Override appConfigProvider or register one in the service locator.',
  );
});

final environmentProvider = Provider<EnvironmentFlavor>(
  (ref) => ref.watch(appConfigProvider).environment,
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
