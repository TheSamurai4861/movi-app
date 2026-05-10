import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/startup/domain/boot_contracts.dart';
import 'package:movi/src/core/startup/domain/startup_contracts.dart';
import 'package:movi/src/core/startup/domain/startup_recovery_mapper.dart';

void main() {
  const mapper = StartupRecoveryMapper();

  group('mapBootFailure', () {
    test('maps config timeout to retry and export logs', () {
      final plan = mapper.mapBootFailure(StartupFailureCode.configTimeout);

      expect(plan.reasonCode, StartupRecoveryReasonCodes.bootConfigTimeout);
      expect(plan.actions, const [
        RecoveryAction.retry,
        RecoveryAction.exportLogs,
      ]);
      expect(plan.hasPrimaryAction, isTrue);
    });

    test('maps dependency timeout to retry and export logs', () {
      final plan = mapper.mapBootFailure(
        StartupFailureCode.dependenciesInitTimeout,
      );

      expect(
        plan.reasonCode,
        StartupRecoveryReasonCodes.bootDependenciesTimeout,
      );
      expect(plan.actions, const [
        RecoveryAction.retry,
        RecoveryAction.exportLogs,
      ]);
      expect(plan.hasPrimaryAction, isTrue);
    });

    test('maps startup failure instances through their typed code', () {
      final plan = mapper.mapBootFailure(
        StartupFailure(
          code: StartupFailureCode.dependenciesInitFailed,
          phase: StartupPhase.initDependencies,
          message: 'startup_failed',
          original: StateError('dependencies failed'),
        ),
      );

      expect(plan.reasonCode, StartupRecoveryReasonCodes.bootTechnicalFailure);
      expect(plan.actions, contains(RecoveryAction.retry));
      expect(plan.actions, contains(RecoveryAction.exportLogs));
    });

    test('maps unknown boot errors to stable retry fallback', () {
      final plan = mapper.mapBootFailure(StateError('unknown'));

      expect(plan.reasonCode, StartupRecoveryReasonCodes.bootTechnicalFailure);
      expect(plan.actions, const [
        RecoveryAction.retry,
        RecoveryAction.exportLogs,
      ]);
      expect(plan.hasPrimaryAction, isTrue);
    });
  });

  group('mapLaunchFailure', () {
    test('maps IPTV network timeout to retry or choose source', () {
      final plan = mapper.mapLaunchFailure(
        step: 'preload_complete_home',
        errorCode: 'iptvNetworkTimeout',
        original: StateError('timeout'),
      );

      expect(plan.reasonCode, StartupRecoveryReasonCodes.catalogSyncTimeout);
      expect(plan.actions, const [
        RecoveryAction.retry,
        RecoveryAction.chooseSource,
      ]);
    });

    test('maps IPTV provider error to retry or choose source', () {
      final plan = mapper.mapLaunchFailure(
        step: 'preload_complete_home',
        errorCode: 'iptvProviderError',
        original: StateError('provider'),
      );

      expect(plan.reasonCode, StartupRecoveryReasonCodes.catalogProviderError);
      expect(plan.actions, const [
        RecoveryAction.retry,
        RecoveryAction.chooseSource,
      ]);
    });

    test('maps IPTV empty data to resync or choose source', () {
      final plan = mapper.mapLaunchFailure(
        step: 'preload_complete_home',
        errorCode: 'iptvEmptyData',
        original: StateError('empty'),
      );

      expect(plan.reasonCode, StartupRecoveryReasonCodes.catalogEmpty);
      expect(plan.actions, const [
        RecoveryAction.resyncSource,
        RecoveryAction.chooseSource,
      ]);
    });

    test('maps library timeout to retry library', () {
      final plan = mapper.mapLaunchFailure(
        step: 'preload_complete_home',
        errorCode: 'libraryPreloadTimeout',
        original: StateError('library timeout'),
      );

      expect(plan.reasonCode, StartupRecoveryReasonCodes.libraryPreloadTimeout);
      expect(plan.actions, const [RecoveryAction.retryLibrary]);
    });

    test('maps home preload invalid state to explicit fallback', () {
      final plan = mapper.mapLaunchFailure(
        step: 'preload_complete_home',
        errorCode: 'homePreloadInvalidState',
        original: StateError('home invalid'),
      );

      expect(
        plan.reasonCode,
        StartupRecoveryReasonCodes.homePreloadInvalidState,
      );
      expect(plan.actions, const [
        RecoveryAction.retry,
        RecoveryAction.exportLogs,
      ]);
    });

    test('maps unknown launch errors to stable retry fallback', () {
      final plan = mapper.mapLaunchFailure(
        step: 'unknown_step',
        errorCode: 'unexpected',
        original: StateError('unexpected'),
      );

      expect(plan.reasonCode, StartupRecoveryReasonCodes.bootTechnicalFailure);
      expect(plan.actions, const [
        RecoveryAction.retry,
        RecoveryAction.exportLogs,
      ]);
    });
  });

  group('mapHomeFailure', () {
    test('maps home feed failure to retry home sections', () {
      final plan = mapper.mapHomeFailure(
        reasonCode: StartupRecoveryReasonCodes.homeFeedFailed,
      );

      expect(plan.reasonCode, StartupRecoveryReasonCodes.homeFeedFailed);
      expect(plan.actions, const [RecoveryAction.retryHomeSections]);
    });

    test(
      'maps empty IPTV Home sections to section retry and source resync',
      () {
        final plan = mapper.mapHomeFailure(
          reasonCode: StartupRecoveryReasonCodes.homeIptvSectionsEmpty,
        );

        expect(
          plan.reasonCode,
          StartupRecoveryReasonCodes.homeIptvSectionsEmpty,
        );
        expect(plan.actions, const [
          RecoveryAction.retryHomeSections,
          RecoveryAction.resyncSource,
        ]);
      },
    );

    test('maps partial Home failure to combined Home actions', () {
      final plan = mapper.mapHomeFailure(
        reasonCode: StartupRecoveryReasonCodes.homePartial,
      );

      expect(plan.reasonCode, StartupRecoveryReasonCodes.homePartial);
      expect(plan.actions, const [
        RecoveryAction.retryHomeSections,
        RecoveryAction.retryLibrary,
      ]);
    });

    test('maps library preload failure to retry library', () {
      final plan = mapper.mapHomeFailure(
        reasonCode: StartupRecoveryReasonCodes.libraryPreloadFailed,
      );

      expect(plan.reasonCode, StartupRecoveryReasonCodes.libraryPreloadFailed);
      expect(plan.actions, const [RecoveryAction.retryLibrary]);
    });

    test('maps catalog snapshot missing to resync or choose source', () {
      final plan = mapper.mapHomeFailure(
        reasonCode: StartupRecoveryReasonCodes.catalogSnapshotMissing,
      );

      expect(
        plan.reasonCode,
        StartupRecoveryReasonCodes.catalogSnapshotMissing,
      );
      expect(plan.actions, const [
        RecoveryAction.resyncSource,
        RecoveryAction.chooseSource,
      ]);
    });
  });

  test('every mapped plan exposes at least one action', () {
    final plans = <StartupRecoveryPlan>[
      mapper.mapBootFailure(StartupFailureCode.configTimeout),
      mapper.mapBootFailure(StartupFailureCode.dependenciesInitTimeout),
      mapper.mapBootFailure(StateError('unknown')),
      mapper.mapLaunchFailure(
        step: 'preload_complete_home',
        errorCode: 'iptvNetworkTimeout',
        original: StateError('timeout'),
      ),
      mapper.mapLaunchFailure(
        step: 'preload_complete_home',
        errorCode: 'iptvProviderError',
        original: StateError('provider'),
      ),
      mapper.mapLaunchFailure(
        step: 'preload_complete_home',
        errorCode: 'iptvEmptyData',
        original: StateError('empty'),
      ),
      mapper.mapLaunchFailure(
        step: 'preload_complete_home',
        errorCode: 'libraryPreloadTimeout',
        original: StateError('library'),
      ),
      mapper.mapHomeFailure(
        reasonCode: StartupRecoveryReasonCodes.homeFeedFailed,
      ),
      mapper.mapHomeFailure(
        reasonCode: StartupRecoveryReasonCodes.homeIptvSectionsEmpty,
      ),
      mapper.mapHomeFailure(
        reasonCode: StartupRecoveryReasonCodes.libraryPreloadFailed,
      ),
    ];

    for (final plan in plans) {
      expect(
        plan.actions,
        isNotEmpty,
        reason: '${plan.reasonCode} should expose an action',
      );
      expect(
        plan.hasPrimaryAction,
        isTrue,
        reason: '${plan.reasonCode} should expose a primary action',
      );
    }
  });

  test('technical recovery plans include retry', () {
    final plans = <StartupRecoveryPlan>[
      mapper.mapBootFailure(StartupFailureCode.configTimeout),
      mapper.mapBootFailure(StartupFailureCode.dependenciesInitTimeout),
      mapper.mapBootFailure(StartupFailureCode.configInvalid),
      mapper.mapLaunchFailure(
        step: 'unknown_step',
        errorCode: 'unexpected',
        original: StateError('unexpected'),
      ),
    ];

    for (final plan in plans) {
      expect(
        plan.actions,
        contains(RecoveryAction.retry),
        reason: '${plan.reasonCode} should allow retry',
      );
    }
  });
}
