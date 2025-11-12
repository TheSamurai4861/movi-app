import 'package:flutter_riverpod/legacy.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/state/app_state.dart';
import 'package:movi/src/core/state/app_state_controller.dart';

final appStateControllerProvider =
    StateNotifierProvider<AppStateController, AppState>(
      (ref) => sl<AppStateController>(),
    );
