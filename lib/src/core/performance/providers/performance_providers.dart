import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/performance/domain/performance_tuning.dart';

final performanceTuningProvider = Provider<PerformanceTuning>(
  (ref) => ref.watch(slProvider)<PerformanceTuning>(),
);

