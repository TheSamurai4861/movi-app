import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/startup/app_launch_criteria.dart';
import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/core/startup/domain/boot_contracts.dart';
import 'package:movi/src/core/startup/domain/startup_recovery_mapper.dart';
import 'package:movi/src/core/startup/presentation/boot_action_handler.dart';
import 'package:movi/src/core/startup/presentation/boot_screen_mapper.dart';
import 'package:movi/src/core/startup/presentation/boot_screen_model.dart';
import 'package:movi/src/features/welcome/domain/enum.dart';

void main() {
  const mapper = BootScreenMapper();

  group('BootScreenMapper', () {
    test('maps running preload phase to catalog loading', () {
      final model = mapper.fromLaunchState(
        const AppLaunchState(
          status: AppLaunchStatus.running,
          phase: AppLaunchPhase.preloadCompleteHome,
        ),
      );

      expect(model.screenType, BootScreenType.catalogLoading);
      expect(model.reasonCode, 'catalog_preparing');
      expect(model.isInteractive, isFalse);
      expect(model.primaryAction, isNull);
      expect(model.initialFocus, BootFocusTarget.none);
    });

    test('maps auth destination to login action', () {
      final model = mapper.fromLaunchState(
        const AppLaunchState(
          status: AppLaunchStatus.success,
          destination: BootstrapDestination.auth,
        ),
      );

      expect(model.screenType, BootScreenType.actionRequired);
      expect(model.reasonCode, 'auth_required');
      expect(model.primaryAction, BootActionIntent.login);
      expect(model.destination, BootstrapDestination.auth);
      expect(model.initialFocus, BootFocusTarget.primaryAction);
    });

    test('maps source selection destination to choose source action', () {
      final model = mapper.fromLaunchState(
        const AppLaunchState(
          status: AppLaunchStatus.success,
          destination: BootstrapDestination.chooseSource,
        ),
      );

      expect(model.screenType, BootScreenType.actionRequired);
      expect(model.reasonCode, 'source_selection_required');
      expect(model.primaryAction, BootActionIntent.chooseSource);
      expect(model.destination, BootstrapDestination.chooseSource);
    });

    test('maps catalog timeout recovery to retry and change source', () {
      final model = mapper.fromLaunchState(
        AppLaunchState(
          status: AppLaunchStatus.success,
          destination: BootstrapDestination.welcomeSources,
          recoveryPlan: StartupRecoveryPlan(
            reasonCode: StartupRecoveryReasonCodes.catalogSyncTimeout,
            actions: <RecoveryAction>[
              RecoveryAction.retry,
              RecoveryAction.chooseSource,
            ],
          ),
        ),
      );

      expect(model.screenType, BootScreenType.actionRequired);
      expect(model.reasonCode, StartupRecoveryReasonCodes.catalogSyncTimeout);
      expect(model.title, 'La source ne repond pas');
      expect(model.primaryAction, BootActionIntent.retry);
      expect(model.primaryActionLabel, 'Reessayer');
      expect(model.secondaryAction, BootActionIntent.chooseSource);
      expect(model.secondaryActionLabel, 'Changer de source');
      expect(model.initialFocus, BootFocusTarget.primaryAction);
    });

    test(
      'maps invalid credentials recovery to reconnect without source change',
      () {
        final model = mapper.fromLaunchState(
          AppLaunchState(
            status: AppLaunchStatus.success,
            destination: BootstrapDestination.welcomeSources,
            recoveryPlan: StartupRecoveryPlan(
              reasonCode: StartupRecoveryReasonCodes.catalogCredentialsInvalid,
              actions: <RecoveryAction>[RecoveryAction.reconnectSource],
            ),
          ),
        );

        expect(
          model.reasonCode,
          StartupRecoveryReasonCodes.catalogCredentialsInvalid,
        );
        expect(model.title, 'Connexion a la source impossible');
        expect(model.primaryAction, BootActionIntent.reconnectSource);
        expect(model.primaryActionLabel, 'Reconnecter la source');
        expect(model.secondaryAction, isNull);
      },
    );

    test('maps ready home destination to opening home without action', () {
      final model = mapper.fromLaunchState(
        const AppLaunchState(
          status: AppLaunchStatus.success,
          destination: BootstrapDestination.home,
          criteria: AppLaunchCriteria(
            hasSession: true,
            hasSelectedProfile: true,
            hasSelectedSource: true,
            hasIptvCatalogReady: true,
            hasHomePreloaded: true,
            hasLibraryReady: true,
          ),
        ),
      );

      expect(model.screenType, BootScreenType.openingHome);
      expect(model.reasonCode, 'home_ready');
      expect(model.isInteractive, isFalse);
      expect(model.primaryAction, isNull);
      expect(model.destination, BootstrapDestination.home);
    });

    test('non interactive states do not expose focusable actions', () {
      final states = <AppLaunchState>[
        const AppLaunchState(),
        const AppLaunchState(
          status: AppLaunchStatus.running,
          phase: AppLaunchPhase.startup,
        ),
        const AppLaunchState(
          status: AppLaunchStatus.running,
          phase: AppLaunchPhase.auth,
        ),
        const AppLaunchState(
          status: AppLaunchStatus.running,
          phase: AppLaunchPhase.profiles,
        ),
        const AppLaunchState(
          status: AppLaunchStatus.running,
          phase: AppLaunchPhase.sources,
        ),
        const AppLaunchState(
          status: AppLaunchStatus.running,
          phase: AppLaunchPhase.preloadCompleteHome,
        ),
        const AppLaunchState(
          status: AppLaunchStatus.running,
          phase: AppLaunchPhase.done,
        ),
        const AppLaunchState(
          status: AppLaunchStatus.success,
          destination: BootstrapDestination.home,
          criteria: AppLaunchCriteria(
            hasSession: true,
            hasSelectedProfile: true,
            hasSelectedSource: true,
            hasIptvCatalogReady: true,
            hasHomePreloaded: true,
            hasLibraryReady: true,
          ),
        ),
      ];

      for (final state in states) {
        final model = mapper.fromLaunchState(state);

        expect(
          model.isInteractive,
          isFalse,
          reason: 'state=${state.status.name}/${state.phase.name}',
        );
        expect(model.primaryAction, isNull);
        expect(model.secondaryAction, isNull);
        expect(model.initialFocus, BootFocusTarget.none);
      }
    });

    test('interactive states declare a primary action and focus target', () {
      final states = <AppLaunchState>[
        const AppLaunchState(
          status: AppLaunchStatus.success,
          destination: BootstrapDestination.auth,
        ),
        const AppLaunchState(
          status: AppLaunchStatus.success,
          destination: BootstrapDestination.welcomeUser,
        ),
        const AppLaunchState(
          status: AppLaunchStatus.success,
          destination: BootstrapDestination.welcomeSources,
        ),
        const AppLaunchState(
          status: AppLaunchStatus.success,
          destination: BootstrapDestination.chooseSource,
        ),
        const AppLaunchState(status: AppLaunchStatus.failure),
      ];

      for (final state in states) {
        final model = mapper.fromLaunchState(state);

        expect(
          model.isInteractive,
          isTrue,
          reason: 'state=${state.status.name}/${state.destination?.name}',
        );
        expect(model.primaryAction, isNotNull);
        expect(model.primaryActionLabel, isNotNull);
        expect(model.initialFocus, BootFocusTarget.primaryAction);
      }
    });

    test('maps failure to technical failure with retry and export logs', () {
      final model = mapper.fromLaunchState(
        const AppLaunchState(status: AppLaunchStatus.failure),
      );

      expect(model.screenType, BootScreenType.technicalFailure);
      expect(model.reasonCode, 'technical_failure');
      expect(model.primaryAction, BootActionIntent.retry);
      expect(model.secondaryAction, BootActionIntent.exportLogs);
      expect(model.initialFocus, BootFocusTarget.primaryAction);
    });

    test('does not leak reason code into user visible text fields', () {
      final model = mapper.fromLaunchState(
        const AppLaunchState(
          status: AppLaunchStatus.success,
          destination: BootstrapDestination.chooseSource,
        ),
      );

      final visibleTexts = <String?>[
        model.title,
        model.message,
        model.secondaryMessage,
        model.primaryActionLabel,
        model.secondaryActionLabel,
      ].whereType<String>();

      for (final text in visibleTexts) {
        expect(text, isNot(model.reasonCode));
      }
    });
  });
}
