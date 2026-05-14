import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/router/app_route_paths.dart';
import 'package:movi/src/core/startup/domain/boot_contracts.dart';
import 'package:movi/src/core/startup/presentation/boot_action_handler.dart';

void main() {
  const planner = BootActionPlanner();

  BootActionPlan plan(BootActionIntent intent, {String? destinationOverride}) {
    return planner.plan(
      BootActionRequest(
        intent: intent,
        reasonCode: 'test_reason',
        destinationOverride: destinationOverride,
      ),
    );
  }

  group('BootActionPlanner', () {
    test('maps retry to a launch rerun target', () {
      final actionPlan = plan(BootActionIntent.retry);

      expect(actionPlan.kind, BootActionExecutionKind.launchRun);
      expect(actionPlan.route, AppRoutePaths.launch);
      expect(actionPlan.runReason, 'boot_action_retry');
    });

    test('maps action page intents to boot routes', () {
      expect(plan(BootActionIntent.login).route, AppRoutePaths.authOtp);
      expect(
        plan(BootActionIntent.createProfile).route,
        AppRoutePaths.welcomeUser,
      );
      expect(
        plan(BootActionIntent.chooseProfile).route,
        AppRoutePaths.welcomeUser,
      );
      expect(
        plan(BootActionIntent.addSource).route,
        AppRoutePaths.welcomeSources,
      );
      expect(
        plan(BootActionIntent.reconnectSource).route,
        AppRoutePaths.welcomeSources,
      );
      expect(
        plan(BootActionIntent.chooseSource).route,
        AppRoutePaths.welcomeSourceSelect,
      );
    });

    test('maps source and Home actions to controller commands', () {
      final resyncPlan = plan(BootActionIntent.resyncSource);
      final sectionsPlan = plan(BootActionIntent.retryHomeSections);
      final libraryPlan = plan(BootActionIntent.retryLibrary);

      expect(
        resyncPlan.controllerCommand,
        BootActionControllerCommand.sourceResync,
      );
      expect(resyncPlan.route, AppRoutePaths.welcomeSourceLoading);
      expect(
        sectionsPlan.controllerCommand,
        BootActionControllerCommand.retryHomeSections,
      );
      expect(sectionsPlan.route, AppRoutePaths.home);
      expect(
        libraryPlan.controllerCommand,
        BootActionControllerCommand.retryLibrary,
      );
      expect(libraryPlan.route, AppRoutePaths.home);
    });

    test('maps openHome to Home navigation', () {
      final actionPlan = plan(BootActionIntent.openHome);

      expect(actionPlan.kind, BootActionExecutionKind.navigation);
      expect(actionPlan.route, AppRoutePaths.home);
    });

    test('keeps export logs diagnostic and non navigational', () {
      final actionPlan = plan(BootActionIntent.exportLogs);

      expect(actionPlan.kind, BootActionExecutionKind.diagnostic);
      expect(actionPlan.route, isNull);
      expect(
        actionPlan.controllerCommand,
        BootActionControllerCommand.exportLogs,
      );
    });

    test('honors destination override without changing intent kind', () {
      final actionPlan = plan(
        BootActionIntent.chooseSource,
        destinationOverride: AppRoutePaths.iptvSourceSelect,
      );

      expect(actionPlan.kind, BootActionExecutionKind.navigation);
      expect(actionPlan.route, AppRoutePaths.iptvSourceSelect);
    });

    test('every actionable intent produces a route or controller command', () {
      for (final intent in BootActionIntent.values) {
        final actionPlan = plan(intent);

        switch (intent) {
          case BootActionIntent.exportLogs:
            expect(actionPlan.kind, BootActionExecutionKind.diagnostic);
            expect(actionPlan.controllerCommand, isNotNull);
          case BootActionIntent.resyncSource ||
              BootActionIntent.retryHomeSections ||
              BootActionIntent.retryLibrary:
            expect(actionPlan.kind, BootActionExecutionKind.controllerCommand);
            expect(actionPlan.controllerCommand, isNotNull);
            expect(actionPlan.route, isNotNull);
          case BootActionIntent.retry:
            expect(actionPlan.kind, BootActionExecutionKind.launchRun);
            expect(actionPlan.route, AppRoutePaths.launch);
          case BootActionIntent.login ||
              BootActionIntent.createProfile ||
              BootActionIntent.chooseProfile ||
              BootActionIntent.addSource ||
              BootActionIntent.chooseSource ||
              BootActionIntent.reconnectSource ||
              BootActionIntent.openHome:
            expect(actionPlan.kind, BootActionExecutionKind.navigation);
            expect(actionPlan.route, isNotNull);
        }
      }
    });
  });

  group('BootActionIntentFromRecoveryAction', () {
    test('maps every RecoveryAction to a boot action intent', () {
      expect(RecoveryAction.retry.toBootActionIntent(), BootActionIntent.retry);
      expect(
        RecoveryAction.exportLogs.toBootActionIntent(),
        BootActionIntent.exportLogs,
      );
      expect(RecoveryAction.login.toBootActionIntent(), BootActionIntent.login);
      expect(
        RecoveryAction.createProfile.toBootActionIntent(),
        BootActionIntent.createProfile,
      );
      expect(
        RecoveryAction.chooseProfile.toBootActionIntent(),
        BootActionIntent.chooseProfile,
      );
      expect(
        RecoveryAction.addSource.toBootActionIntent(),
        BootActionIntent.addSource,
      );
      expect(
        RecoveryAction.chooseSource.toBootActionIntent(),
        BootActionIntent.chooseSource,
      );
      expect(
        RecoveryAction.reconnectSource.toBootActionIntent(),
        BootActionIntent.reconnectSource,
      );
      expect(
        RecoveryAction.resyncSource.toBootActionIntent(),
        BootActionIntent.resyncSource,
      );
      expect(
        RecoveryAction.openHomeCached.toBootActionIntent(),
        BootActionIntent.openHome,
      );
      expect(
        RecoveryAction.retryHomeSections.toBootActionIntent(),
        BootActionIntent.retryHomeSections,
      );
      expect(
        RecoveryAction.retryLibrary.toBootActionIntent(),
        BootActionIntent.retryLibrary,
      );
    });
  });
}
