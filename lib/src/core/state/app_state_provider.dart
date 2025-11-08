import 'package:flutter_riverpod/legacy.dart';

import '../di/injector.dart';
import 'app_state.dart';
import 'app_state_controller.dart';

final appStateControllerProvider = StateNotifierProvider<AppStateController, AppState>(
  (ref) => sl<AppStateController>(),
);
