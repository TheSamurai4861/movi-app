import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/core/config/config.dart';
import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/core/startup/boot_event_contract_logger.dart';

import 'package:movi/src/core/startup/presentation/boot_action_handler.dart';
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';

Future<BootActionResult> executeBootAction(
  BuildContext context,
  WidgetRef ref,
  BootActionRequest request, {
  BootActionPlanner planner = const BootActionPlanner(),
}) async {
  var telemetryEnabled = false;
  try {
    final flags = ref.read(featureFlagsProvider);
    telemetryEnabled =
        flags.enableTelemetry && flags.enableEntryJourneyTelemetryV2;
  } catch (_) {
    telemetryEnabled = false;
  }
  final contractLogger = BootEventContractLogger(enabled: telemetryEnabled);
  AppLaunchState? launchState;
  try {
    launchState = ref.read(appLaunchStateProvider);
  } catch (_) {
    // Isolated page tests can execute boot actions without the startup graph.
    // The action should still navigate to the planned route.
  }
  final plan = planner.plan(request);
  contractLogger.emit(
    event: BootContractEvent.bootActionTriggered,
    runId: launchState?.runId ?? 'missing',
    phase: launchState?.phase.name,
    reasonCode: request.reasonCode,
    destination: launchState?.destination?.name,
    action: request.intent.name,
    fields: <String, Object?>{
      'execution_kind': plan.kind.name,
      'route': plan.route,
      'run_reason': plan.runReason,
    },
  );
  final sourceEvent = _sourceEventForReasonCode(request.reasonCode);
  if (sourceEvent != null) {
    contractLogger.emit(
      event: sourceEvent,
      runId: launchState?.runId ?? 'missing',
      phase: launchState?.phase.name,
      reasonCode: request.reasonCode,
      action: request.intent.name,
      fields: <String, Object?>{'route': plan.route},
    );
  }

  switch (plan.kind) {
    case BootActionExecutionKind.launchRun:
      try {
        final orchestrator = ref.read(appLaunchOrchestratorProvider.notifier);
        orchestrator.reset();
        unawaited(
          orchestrator.run().then<void>(
            (_) {},
            onError: (Object _, StackTrace __) {},
          ),
        );
      } catch (_) {
        // Some isolated route tests mount auth pages without the startup graph.
        // Navigating to /launch still hands control back to the real bootstrap
        // surface in the app, so reset is best-effort here.
      }
      if (context.mounted && plan.route != null) {
        context.go(plan.route!);
      }
    case BootActionExecutionKind.navigation:
      if (context.mounted && plan.route != null) {
        context.go(plan.route!);
      }
    case BootActionExecutionKind.controllerCommand:
      if (context.mounted && plan.route != null) {
        context.go(plan.route!);
      }
    case BootActionExecutionKind.diagnostic:
      // The export service is not wired yet. Keep the action handled by the
      // contract so renderers do not invent ad-hoc callbacks.
      break;
  }

  return BootActionResult(request: request, plan: plan, handled: true);
}

BootContractEvent? _sourceEventForReasonCode(String reasonCode) {
  return switch (reasonCode.trim()) {
    'source_connected' => BootContractEvent.sourceConnected,
    'source_selected' => BootContractEvent.sourceSelected,
    _ => null,
  };
}
