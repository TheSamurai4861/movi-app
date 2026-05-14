import 'package:movi/src/core/router/app_route_paths.dart';
import 'package:movi/src/core/startup/domain/tunnel_state.dart';
import 'package:movi/src/features/welcome/domain/enum.dart';

enum TunnelSurface {
  preparingSystem,
  auth,
  createProfile,
  chooseProfile,
  chooseSource,
  loadingMedia,
  home,
}

final class TunnelSurfaceMapper {
  const TunnelSurfaceMapper._();

  static TunnelSurface fromTunnelState(TunnelState state) {
    switch (state.stage) {
      case TunnelStage.preparingSystem:
        return TunnelSurface.preparingSystem;
      case TunnelStage.authRequired:
        return TunnelSurface.auth;
      case TunnelStage.profileRequired:
        return state.profilesCount > 0
            ? TunnelSurface.chooseProfile
            : TunnelSurface.createProfile;
      case TunnelStage.sourceRequired:
        return TunnelSurface.chooseSource;
      case TunnelStage.preloadingHome:
        return TunnelSurface.loadingMedia;
      case TunnelStage.readyForHome:
        return TunnelSurface.home;
    }
  }
}

final class TunnelSurfaceRouteMapper {
  const TunnelSurfaceRouteMapper._();

  static String routeForSurface({
    required TunnelSurface surface,
    required TunnelState tunnelState,
    required String currentLocation,
  }) {
    switch (surface) {
      case TunnelSurface.preparingSystem:
        return tunnelState.reasonCode == 'launch_failure'
            ? AppRoutePaths.bootstrap
            : AppRoutePaths.launch;
      case TunnelSurface.auth:
        return AppRoutePaths.authOtp;
      case TunnelSurface.createProfile:
      case TunnelSurface.chooseProfile:
        return AppRoutePaths.welcomeUser;
      case TunnelSurface.chooseSource:
        return tunnelState.legacyDestination ==
                BootstrapDestination.chooseSource
            ? AppRoutePaths.welcomeSourceSelect
            : AppRoutePaths.welcomeSources;
      case TunnelSurface.loadingMedia:
        // Phase 5.6: route legacy /welcome/sources/loading no longer used as
        // canonical loading surface. Keep bootstrap as the single loading route.
        return AppRoutePaths.bootstrap;
      case TunnelSurface.home:
        return AppRoutePaths.home;
    }
  }
}
