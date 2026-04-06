import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/core/startup/domain/tunnel_state.dart';
import 'package:movi/src/features/welcome/domain/enum.dart';

final class CanonicalTunnelStateProjector {
  const CanonicalTunnelStateProjector();

  TunnelState fromLaunchState(AppLaunchState launchState) {
    final criteria = launchState.criteria;
    final executionMode =
        launchState.recovery?.kind == AppLaunchRecoveryKind.reauthRequired
        ? TunnelExecutionMode.cloud
        : launchState.recovery?.kind ==
                  AppLaunchRecoveryKind.degradedRetryable ||
              !criteria.hasSession
        ? TunnelExecutionMode.localFirst
        : TunnelExecutionMode.cloud;

    final loadingState = switch (launchState.status) {
      AppLaunchStatus.idle => TunnelLoadingState.idle,
      AppLaunchStatus.running => TunnelLoadingState.inProgress,
      AppLaunchStatus.success ||
      AppLaunchStatus.failure => TunnelLoadingState.completed,
    };

    if (launchState.status == AppLaunchStatus.failure) {
      return _buildState(
        launchState: launchState,
        stage: TunnelStage.preparingSystem,
        executionMode: executionMode,
        loadingState: loadingState,
        reasonCode: 'launch_failure',
      );
    }

    if (launchState.status != AppLaunchStatus.success) {
      return _buildState(
        launchState: launchState,
        stage: TunnelStage.preparingSystem,
        executionMode: executionMode,
        loadingState: loadingState,
        reasonCode: launchState.status == AppLaunchStatus.running
            ? 'launch_running'
            : 'launch_idle',
      );
    }

    if (launchState.recovery?.kind == AppLaunchRecoveryKind.reauthRequired ||
        launchState.destination == BootstrapDestination.auth) {
      return _buildState(
        launchState: launchState,
        stage: TunnelStage.authRequired,
        executionMode: TunnelExecutionMode.cloud,
        loadingState: loadingState,
        reasonCode: launchState.recovery?.reasonCode ?? 'auth_required',
      );
    }

    if (!criteria.hasSelectedProfile ||
        launchState.destination == BootstrapDestination.welcomeUser) {
      return _buildState(
        launchState: launchState,
        stage: TunnelStage.profileRequired,
        executionMode: executionMode,
        loadingState: loadingState,
        reasonCode: 'profile_required',
      );
    }

    if (!criteria.hasSelectedSource ||
        launchState.destination == BootstrapDestination.welcomeSources ||
        launchState.destination == BootstrapDestination.chooseSource) {
      return _buildState(
        launchState: launchState,
        stage: TunnelStage.sourceRequired,
        executionMode: executionMode,
        loadingState: loadingState,
        reasonCode: launchState.destination == BootstrapDestination.chooseSource
            ? 'source_selection_required'
            : 'source_required',
      );
    }

    if (criteria.isHomeReady &&
        launchState.destination == BootstrapDestination.home) {
      return _buildState(
        launchState: launchState,
        stage: TunnelStage.readyForHome,
        executionMode: executionMode,
        loadingState: loadingState,
        reasonCode: 'home_ready',
      );
    }

    return _buildState(
      launchState: launchState,
      stage: TunnelStage.preloadingHome,
      executionMode: executionMode,
      loadingState: loadingState,
      reasonCode: 'preloading_home',
    );
  }

  TunnelState _buildState({
    required AppLaunchState launchState,
    required TunnelStage stage,
    required TunnelExecutionMode executionMode,
    required TunnelLoadingState loadingState,
    required String reasonCode,
  }) {
    final criteria = launchState.criteria;
    return TunnelState(
      stage: stage,
      executionMode: executionMode,
      loadingState: loadingState,
      reasonCode: reasonCode,
      hasSession: criteria.hasSession,
      hasSelectedProfile: criteria.hasSelectedProfile,
      hasSelectedSource: criteria.hasSelectedSource,
      hasCatalogReady: criteria.hasIptvCatalogReady,
      hasHomePreloaded: criteria.hasHomePreloaded,
      hasLibraryReady: criteria.hasLibraryReady,
      profilesCount: criteria.hasSelectedProfile ? 1 : 0,
      sourcesCount: criteria.hasSelectedSource ? 1 : 0,
      isShadowMode: false,
      legacyDestination: launchState.destination,
    );
  }
}
