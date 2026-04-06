import 'package:movi/src/core/startup/app_launch_criteria.dart';
import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/core/startup/domain/tunnel_state.dart';
import 'package:movi/src/features/welcome/domain/enum.dart';

final class LegacyTunnelStateBridge {
  const LegacyTunnelStateBridge();

  TunnelState fromLaunchState(AppLaunchState launchState) {
    final criteria = launchState.criteria;
    final destination = launchState.destination;
    final phase = launchState.phase;

    final executionMode =
        launchState.recovery?.kind == AppLaunchRecoveryKind.reauthRequired
        ? TunnelExecutionMode.cloud
        : criteria.hasSession
        ? TunnelExecutionMode.cloud
        : TunnelExecutionMode.localFirst;

    switch (launchState.status) {
      case AppLaunchStatus.idle:
        return TunnelState.empty.copyWith(
          executionMode: executionMode,
          reasonCode: 'tunnel_idle',
        );
      case AppLaunchStatus.running:
        return TunnelState(
          stage: _stageForPhase(phase),
          executionMode: executionMode,
          loadingState: TunnelLoadingState.inProgress,
          reasonCode: 'legacy_phase_${phase.name}',
          hasSession: criteria.hasSession,
          hasSelectedProfile: criteria.hasSelectedProfile,
          hasSelectedSource: criteria.hasSelectedSource,
          hasCatalogReady: criteria.hasIptvCatalogReady,
          hasHomePreloaded: criteria.hasHomePreloaded,
          hasLibraryReady: criteria.hasLibraryReady,
          profilesCount: 0,
          sourcesCount: 0,
          isShadowMode: false,
          legacyDestination: destination,
        );
      case AppLaunchStatus.failure:
        return TunnelState(
          stage: _stageForPhase(phase),
          executionMode: executionMode,
          loadingState: TunnelLoadingState.completed,
          reasonCode: launchState.recovery?.reasonCode ?? 'legacy_failure',
          hasSession: criteria.hasSession,
          hasSelectedProfile: criteria.hasSelectedProfile,
          hasSelectedSource: criteria.hasSelectedSource,
          hasCatalogReady: criteria.hasIptvCatalogReady,
          hasHomePreloaded: criteria.hasHomePreloaded,
          hasLibraryReady: criteria.hasLibraryReady,
          profilesCount: 0,
          sourcesCount: 0,
          isShadowMode: false,
          legacyDestination: destination,
        );
      case AppLaunchStatus.success:
        return TunnelState(
          stage: _stageForDestination(destination, criteria),
          executionMode: executionMode,
          loadingState: TunnelLoadingState.completed,
          reasonCode:
              launchState.recovery?.reasonCode ??
              _reasonCodeForDestination(destination, criteria),
          hasSession: criteria.hasSession,
          hasSelectedProfile: criteria.hasSelectedProfile,
          hasSelectedSource: criteria.hasSelectedSource,
          hasCatalogReady: criteria.hasIptvCatalogReady,
          hasHomePreloaded: criteria.hasHomePreloaded,
          hasLibraryReady: criteria.hasLibraryReady,
          profilesCount: 0,
          sourcesCount: 0,
          isShadowMode: false,
          legacyDestination: destination,
        );
    }
  }

  TunnelStage _stageForPhase(AppLaunchPhase phase) => switch (phase) {
    AppLaunchPhase.init ||
    AppLaunchPhase.startup => TunnelStage.preparingSystem,
    AppLaunchPhase.auth => TunnelStage.authRequired,
    AppLaunchPhase.profiles => TunnelStage.profileRequired,
    AppLaunchPhase.sources ||
    AppLaunchPhase.localAccounts ||
    AppLaunchPhase.sourceSelection => TunnelStage.sourceRequired,
    AppLaunchPhase.preloadCompleteHome => TunnelStage.preloadingHome,
    AppLaunchPhase.done => TunnelStage.preparingSystem,
  };

  TunnelStage _stageForDestination(
    BootstrapDestination? destination,
    AppLaunchCriteria criteria,
  ) {
    return switch (destination) {
      BootstrapDestination.auth => TunnelStage.authRequired,
      BootstrapDestination.welcomeUser => TunnelStage.profileRequired,
      BootstrapDestination.welcomeSources ||
      BootstrapDestination.chooseSource => TunnelStage.sourceRequired,
      BootstrapDestination.home =>
        criteria.isHomeReady
            ? TunnelStage.readyForHome
            : TunnelStage.preloadingHome,
      null =>
        criteria.isHomeReady
            ? TunnelStage.readyForHome
            : TunnelStage.preparingSystem,
    };
  }

  String _reasonCodeForDestination(
    BootstrapDestination? destination,
    AppLaunchCriteria criteria,
  ) {
    return switch (destination) {
      BootstrapDestination.auth => 'auth_required',
      BootstrapDestination.welcomeUser => 'profile_required',
      BootstrapDestination.welcomeSources => 'source_missing',
      BootstrapDestination.chooseSource => 'source_selection_required',
      BootstrapDestination.home =>
        criteria.isHomeReady ? 'home_ready' : 'preloading_home',
      null => 'legacy_destination_missing',
    };
  }
}
