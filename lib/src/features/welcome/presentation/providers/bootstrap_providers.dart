// lib/src/features/welcome/presentation/providers/bootstrap_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/core/logging/logging.dart';
import 'package:movi/src/core/utils/unawaited.dart';

typedef AppLaunchRunner = Future<AppLaunchResult> Function(String reason);

final appLaunchOrchestratorProvider =
    NotifierProvider<AppLaunchOrchestrator, AppLaunchState>(
      AppLaunchOrchestrator.new,
    );

final appLaunchStateProvider = Provider<AppLaunchState>((ref) {
  return ref.watch(appLaunchOrchestratorProvider);
});

final appLaunchRunnerProvider = Provider<AppLaunchRunner>((ref) {
  return (String reason) async {
    final ts = DateTime.now().toIso8601String();
    unawaited(
      LoggingService.log(
        '[AppLaunch] ts=$ts action=run reason=$reason',
      ),
    );
    return ref.read(appLaunchOrchestratorProvider.notifier).run();
  };
});
