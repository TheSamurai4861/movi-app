import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/state/app_state_controller.dart';

final appStateControllerProvider = Provider<AppStateController>(
  (ref) => ref.watch(slProvider)<AppStateController>(),
);
