import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/startup/app_launch_criteria.dart';
import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/core/startup/domain/tunnel_state.dart';
import 'package:movi/src/core/startup/entry_journey_shadow_bridge.dart';
import 'package:movi/src/features/welcome/domain/enum.dart';

void main() {
  const bridge = LegacyTunnelStateBridge();

  test('maps auth destination to authRequired stage', () {
    const state = AppLaunchState(
      status: AppLaunchStatus.success,
      phase: AppLaunchPhase.done,
      destination: BootstrapDestination.auth,
    );

    final tunnel = bridge.fromLaunchState(state);

    expect(tunnel.stage, TunnelStage.authRequired);
    expect(tunnel.reasonCode, 'auth_required');
  });

  test('maps welcome user destination to profileRequired stage', () {
    const state = AppLaunchState(
      status: AppLaunchStatus.success,
      phase: AppLaunchPhase.done,
      destination: BootstrapDestination.welcomeUser,
    );

    final tunnel = bridge.fromLaunchState(state);

    expect(tunnel.stage, TunnelStage.profileRequired);
    expect(tunnel.reasonCode, 'profile_required');
  });

  test('maps choose source destination to sourceRequired stage', () {
    const state = AppLaunchState(
      status: AppLaunchStatus.success,
      phase: AppLaunchPhase.done,
      destination: BootstrapDestination.chooseSource,
    );

    final tunnel = bridge.fromLaunchState(state);

    expect(tunnel.stage, TunnelStage.sourceRequired);
    expect(tunnel.reasonCode, 'source_selection_required');
  });

  test('maps preloading phase to preloadingHome stage', () {
    const state = AppLaunchState(
      status: AppLaunchStatus.running,
      phase: AppLaunchPhase.preloadCompleteHome,
    );

    final tunnel = bridge.fromLaunchState(state);

    expect(tunnel.stage, TunnelStage.preloadingHome);
    expect(tunnel.loadingState, TunnelLoadingState.inProgress);
  });

  test('maps home success with full criteria to readyForHome stage', () {
    const state = AppLaunchState(
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

    final tunnel = bridge.fromLaunchState(state);

    expect(tunnel.stage, TunnelStage.readyForHome);
    expect(tunnel.reasonCode, 'home_ready');
  });
}
