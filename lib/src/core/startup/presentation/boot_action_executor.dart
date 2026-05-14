import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/core/startup/presentation/boot_action_handler.dart';
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';

Future<BootActionResult> executeBootAction(
  BuildContext context,
  WidgetRef ref,
  BootActionRequest request, {
  BootActionPlanner planner = const BootActionPlanner(),
}) async {
  final plan = planner.plan(request);

  switch (plan.kind) {
    case BootActionExecutionKind.launchRun:
      try {
        ref.read(appLaunchOrchestratorProvider);
        ref.read(appLaunchOrchestratorProvider.notifier).reset();
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
