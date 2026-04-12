import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/focus/application/default_focus_orchestrator.dart';
import 'package:movi/src/core/focus/application/focus_orchestrator.dart';

final focusOrchestratorProvider = Provider<FocusOrchestrator>((ref) {
  return DefaultFocusOrchestrator();
});
