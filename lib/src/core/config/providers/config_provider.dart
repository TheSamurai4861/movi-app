import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/injector.dart';
import '../env/environment.dart';
import '../models/app_config.dart';
import '../models/feature_flags.dart';

final appConfigProvider = Provider<AppConfig>((ref) => sl<AppConfig>());

final environmentProvider = Provider<EnvironmentFlavor>(
  (ref) => sl<EnvironmentFlavor>(),
);

final featureFlagsProvider = Provider<FeatureFlags>(
  (ref) => ref.watch(appConfigProvider).featureFlags,
);
