import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/auth/domain/entities/auth_failures.dart';
import 'package:movi/src/core/startup/app_launch_criteria.dart';
import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/core/startup/canonical_tunnel_state_projector.dart';
import 'package:movi/src/core/startup/domain/tunnel_state.dart';
import 'package:movi/src/features/welcome/domain/enum.dart';

void main() {
  const projector = CanonicalTunnelStateProjector();

  test('projects authRequired when launch resolves to explicit reauth', () {
    const launchState = AppLaunchState(
      status: AppLaunchStatus.success,
      phase: AppLaunchPhase.done,
      destination: BootstrapDestination.auth,
      recovery: AppLaunchRecovery(
        kind: AppLaunchRecoveryKind.reauthRequired,
        cause: AuthFailureCode.invalidSession,
        reasonCode: 'session_expired',
        message: 'Session expired.',
      ),
    );

    final tunnelState = projector.fromLaunchState(launchState);

    expect(tunnelState.stage, TunnelStage.authRequired);
    expect(tunnelState.reasonCode, 'session_expired');
    expect(tunnelState.executionMode, TunnelExecutionMode.cloud);
  });

  test('projects profileRequired when profile selection is missing', () {
    const launchState = AppLaunchState(
      status: AppLaunchStatus.success,
      phase: AppLaunchPhase.done,
      destination: BootstrapDestination.welcomeUser,
      criteria: AppLaunchCriteria(
        hasSession: true,
        hasSelectedProfile: false,
        hasSelectedSource: false,
        hasIptvCatalogReady: false,
        hasHomePreloaded: false,
        hasLibraryReady: false,
      ),
    );

    final tunnelState = projector.fromLaunchState(launchState);

    expect(tunnelState.stage, TunnelStage.profileRequired);
    expect(tunnelState.hasSession, isTrue);
    expect(tunnelState.hasSelectedProfile, isFalse);
  });

  test('projects sourceRequired when source selection is missing', () {
    const launchState = AppLaunchState(
      status: AppLaunchStatus.success,
      phase: AppLaunchPhase.done,
      destination: BootstrapDestination.chooseSource,
      criteria: AppLaunchCriteria(
        hasSession: true,
        hasSelectedProfile: true,
        hasSelectedSource: false,
        hasIptvCatalogReady: false,
        hasHomePreloaded: false,
        hasLibraryReady: false,
      ),
    );

    final tunnelState = projector.fromLaunchState(launchState);

    expect(tunnelState.stage, TunnelStage.sourceRequired);
    expect(tunnelState.reasonCode, 'source_selection_required');
  });

  test('projects preloadingHome when home is not fully ready yet', () {
    const launchState = AppLaunchState(
      status: AppLaunchStatus.success,
      phase: AppLaunchPhase.preloadCompleteHome,
      destination: BootstrapDestination.home,
      criteria: AppLaunchCriteria(
        hasSession: true,
        hasSelectedProfile: true,
        hasSelectedSource: true,
        hasIptvCatalogReady: true,
        hasHomePreloaded: false,
        hasLibraryReady: false,
      ),
    );

    final tunnelState = projector.fromLaunchState(launchState);

    expect(tunnelState.stage, TunnelStage.preloadingHome);
    expect(tunnelState.reasonCode, 'preloading_home');
  });

  test('projects readyForHome when all mandatory criteria are satisfied', () {
    const launchState = AppLaunchState(
      status: AppLaunchStatus.success,
      phase: AppLaunchPhase.done,
      destination: BootstrapDestination.home,
      criteria: AppLaunchCriteria(
        hasSession: true,
        hasSelectedProfile: true,
        hasSelectedSource: true,
        hasIptvCatalogReady: true,
        hasHomePreloaded: true,
        hasLibraryReady: true,
      ),
    );

    final tunnelState = projector.fromLaunchState(launchState);

    expect(tunnelState.stage, TunnelStage.readyForHome);
    expect(tunnelState.reasonCode, 'home_ready');
  });
}
