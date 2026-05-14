import 'package:movi/src/core/router/app_route_paths.dart';
import 'package:movi/src/core/startup/domain/boot_contracts.dart';

/// User or system intent emitted by boot presentation surfaces.
///
/// This enum is presentation-facing: it describes what the UI asks for without
/// carrying Flutter callbacks, controller instances or BuildContext.
enum BootActionIntent {
  retry,
  exportLogs,
  login,
  createProfile,
  chooseProfile,
  addSource,
  chooseSource,
  reconnectSource,
  resyncSource,
  openHome,
  retryHomeSections,
  retryLibrary,
}

extension BootActionIntentFromRecoveryAction on RecoveryAction {
  BootActionIntent toBootActionIntent() {
    return switch (this) {
      RecoveryAction.retry => BootActionIntent.retry,
      RecoveryAction.exportLogs => BootActionIntent.exportLogs,
      RecoveryAction.login => BootActionIntent.login,
      RecoveryAction.createProfile => BootActionIntent.createProfile,
      RecoveryAction.chooseProfile => BootActionIntent.chooseProfile,
      RecoveryAction.addSource => BootActionIntent.addSource,
      RecoveryAction.chooseSource => BootActionIntent.chooseSource,
      RecoveryAction.reconnectSource => BootActionIntent.reconnectSource,
      RecoveryAction.resyncSource => BootActionIntent.resyncSource,
      RecoveryAction.openHomeCached => BootActionIntent.openHome,
      RecoveryAction.retryHomeSections => BootActionIntent.retryHomeSections,
      RecoveryAction.retryLibrary => BootActionIntent.retryLibrary,
    };
  }
}

enum BootActionExecutionKind {
  launchRun,
  navigation,
  controllerCommand,
  diagnostic,
}

/// Stable command names used by the concrete handler to delegate work.
enum BootActionControllerCommand {
  sourceResync,
  retryHomeSections,
  retryLibrary,
  exportLogs,
}

final class BootActionRequest {
  const BootActionRequest({
    required this.intent,
    required this.reasonCode,
    this.destinationOverride,
  }) : assert(reasonCode != '');

  final BootActionIntent intent;
  final String reasonCode;

  /// Optional route override supplied by a screen model.
  ///
  /// The default planner still owns the fallback route for every intent.
  final String? destinationOverride;
}

final class BootActionPlan {
  const BootActionPlan({
    required this.intent,
    required this.kind,
    this.route,
    this.runReason,
    this.controllerCommand,
  }) : assert(
         kind != BootActionExecutionKind.navigation ||
             (route != null && route != ''),
       ),
       assert(
         kind != BootActionExecutionKind.launchRun ||
             (runReason != null && runReason != ''),
       ),
       assert(
         kind != BootActionExecutionKind.controllerCommand ||
             controllerCommand != null,
       );

  final BootActionIntent intent;
  final BootActionExecutionKind kind;
  final String? route;
  final String? runReason;
  final BootActionControllerCommand? controllerCommand;

  bool get navigates => route != null;
}

final class BootActionResult {
  const BootActionResult({
    required this.request,
    required this.plan,
    required this.handled,
  });

  final BootActionRequest request;
  final BootActionPlan plan;
  final bool handled;
}

/// Runtime contract for executing boot actions.
///
/// Concrete implementations may navigate, rerun the orchestrator or delegate to
/// feature controllers. The interface stays small so it can be replaced by a
/// fake in router/widget tests.
abstract interface class BootActionHandler {
  Future<BootActionResult> handle(BootActionRequest request);
}

/// Pure mapping between boot action intentions and their execution target.
///
/// This class has no side effect and does not read providers. It is intentionally
/// separate from [BootActionHandler] so tests can lock the contract before the
/// concrete implementation is wired to GoRouter and controllers.
final class BootActionPlanner {
  const BootActionPlanner();

  BootActionPlan plan(BootActionRequest request) {
    return switch (request.intent) {
      BootActionIntent.retry => BootActionPlan(
        intent: request.intent,
        kind: BootActionExecutionKind.launchRun,
        route: request.destinationOverride ?? AppRoutePaths.launch,
        runReason: 'boot_action_retry',
      ),
      BootActionIntent.exportLogs => BootActionPlan(
        intent: request.intent,
        kind: BootActionExecutionKind.diagnostic,
        controllerCommand: BootActionControllerCommand.exportLogs,
      ),
      BootActionIntent.login => BootActionPlan(
        intent: request.intent,
        kind: BootActionExecutionKind.navigation,
        route: request.destinationOverride ?? AppRoutePaths.authOtp,
      ),
      BootActionIntent.createProfile ||
      BootActionIntent.chooseProfile => BootActionPlan(
        intent: request.intent,
        kind: BootActionExecutionKind.navigation,
        route: request.destinationOverride ?? AppRoutePaths.welcomeUser,
      ),
      BootActionIntent.addSource ||
      BootActionIntent.reconnectSource => BootActionPlan(
        intent: request.intent,
        kind: BootActionExecutionKind.navigation,
        route: request.destinationOverride ?? AppRoutePaths.welcomeSources,
      ),
      BootActionIntent.chooseSource => BootActionPlan(
        intent: request.intent,
        kind: BootActionExecutionKind.navigation,
        route: request.destinationOverride ?? AppRoutePaths.welcomeSourceSelect,
      ),
      BootActionIntent.resyncSource => BootActionPlan(
        intent: request.intent,
        kind: BootActionExecutionKind.controllerCommand,
        route:
            request.destinationOverride ?? AppRoutePaths.welcomeSourceLoading,
        controllerCommand: BootActionControllerCommand.sourceResync,
      ),
      BootActionIntent.openHome => BootActionPlan(
        intent: request.intent,
        kind: BootActionExecutionKind.navigation,
        route: request.destinationOverride ?? AppRoutePaths.home,
      ),
      BootActionIntent.retryHomeSections => BootActionPlan(
        intent: request.intent,
        kind: BootActionExecutionKind.controllerCommand,
        route: request.destinationOverride ?? AppRoutePaths.home,
        controllerCommand: BootActionControllerCommand.retryHomeSections,
      ),
      BootActionIntent.retryLibrary => BootActionPlan(
        intent: request.intent,
        kind: BootActionExecutionKind.controllerCommand,
        route: request.destinationOverride ?? AppRoutePaths.home,
        controllerCommand: BootActionControllerCommand.retryLibrary,
      ),
    };
  }
}
