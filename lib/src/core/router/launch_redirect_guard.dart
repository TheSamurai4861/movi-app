// lib/src/core/router/launch_redirect_guard.dart
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/core/auth/domain/repositories/auth_repository.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/router/app_route_paths.dart';
import 'package:movi/src/core/router/route_catalog.dart';
import 'package:movi/src/core/state/app_state.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/features/welcome/domain/enum.dart';

/// Guard responsable de la logique de redirection initiale.
///
/// Objectif:
/// - Ne pas dupliquer la "state machine" (profil/source) déjà gérée par /bootstrap.
/// - Se contenter de router Launch -> Auth (si pas connecté) -> Bootstrap.
///
/// Utilisé par [GoRouter] comme `redirect` et `refreshListenable`.
class LaunchRedirectGuard extends ChangeNotifier {
  LaunchRedirectGuard({
    required this.logger,
    required AppStateController appStateController,
    required AuthRepository authRepository,
    required AppLaunchStateRegistry launchRegistry,
  })  : _appStateController = appStateController,
        _authRepository = authRepository,
        _launchRegistry = launchRegistry {
    _removeAppStateListener =
        _appStateController.addListener(_onAppStateChanged);
    _launchRegistry.addListener(_onLaunchStateChanged);

    // Initialisation immédiate de l’état d’auth
    _isAuthenticated = _authRepository.currentSession != null;
    _authResolved = _isAuthenticated == true;
    if (!_authResolved) {
      _authResolutionTimer = Timer(
        _authResolveTimeout,
        _onAuthResolutionTimeout,
      );
    }

    // Écoute des changements d’auth (login / logout / refresh)
    _authSubscription =
        _authRepository.onAuthStateChange.listen(_onAuthChanged);
  }

  final AppLogger logger;
  final AppStateController _appStateController;
  final AuthRepository _authRepository;
  final AppLaunchStateRegistry _launchRegistry;

  /// Cache : état d’authentification
  bool? _isAuthenticated;
  bool _authResolved = false;
  Timer? _authResolutionTimer;
  bool _pendingNotify = false;

  static const Duration _authResolveTimeout = Duration(seconds: 4);

  late final void Function() _removeAppStateListener;
  late final StreamSubscription _authSubscription;

  /// Méthode appelée par [GoRouter.redirect].
  FutureOr<String?> handle(BuildContext _, GoRouterState state) {
    final current = state.matchedLocation;

    final onLaunch = current == AppRoutePaths.launch;
    final onAuth = current == AppRoutePaths.authOtp;
    final onBootstrap = current == AppRoutePaths.bootstrap;
    final isStartupRoute = AppRouteCatalog.criticalRoutes.contains(current);
    final launchState = _launchRegistry.state;

    if (!_authResolved) {
      return onLaunch ? null : AppRoutePaths.launch;
    }

    // 1) Pas authentifié -> Auth OTP (sauf si déjà dessus)
    if (_isAuthenticated != true) {
      return onAuth ? null : AppRoutePaths.authOtp;
    }

    if (launchState.status == AppLaunchStatus.running && isStartupRoute) {
      return onLaunch ? null : AppRoutePaths.launch;
    }

    if (launchState.status == AppLaunchStatus.idle && isStartupRoute) {
      return onLaunch ? null : AppRoutePaths.launch;
    }

    if (launchState.status == AppLaunchStatus.failure && isStartupRoute) {
      return onBootstrap ? null : AppRoutePaths.bootstrap;
    }

    if (launchState.status == AppLaunchStatus.success) {
      if (!isStartupRoute) {
        return null;
      }
      final target = _mapDestination(launchState.destination);
      if (target != null && current != target) {
        return target;
      }
      return null;
    }

    // 2) Auth OK -> forcer passage par bootstrap à la sortie de Launch/Auth
    if (onLaunch || onAuth) {
      return AppRoutePaths.bootstrap;
    }

    // 3) Si on est déjà sur bootstrap (ou ailleurs), laisser faire.
    if (onBootstrap) {
      return null;
    }

    return null;
  }

  /// Réagit aux changements de l’AppState.
  ///
  /// Ici on ne redirige pas sur la logique "profil/source", elle est gérée par
  /// /bootstrap via l'orchestrateur. On garde juste le refresh pour que le
  /// router se réévalue quand l'appState change (utile après login / setup).
  void _onAppStateChanged(AppState _) {
    _safeNotify();
  }

  /// Réagit aux changements d’auth (login / logout).
  void _onAuthChanged(_) {
    final isNowAuthenticated = _authRepository.currentSession != null;
    final wasResolved = _authResolved;
    if (!_authResolved) {
      _authResolved = true;
      _authResolutionTimer?.cancel();
      _authResolutionTimer = null;
    }
    if (_isAuthenticated != isNowAuthenticated || !wasResolved) {
      _isAuthenticated = isNowAuthenticated;
      _safeNotify();
    }
  }

  void _onLaunchStateChanged() {
    _safeNotify();
  }

  String? _mapDestination(BootstrapDestination? destination) {
    switch (destination) {
      case BootstrapDestination.auth:
        return AppRoutePaths.authOtp;
      case BootstrapDestination.welcomeUser:
        return AppRoutePaths.welcomeUser;
      case BootstrapDestination.welcomeSources:
        return AppRoutePaths.welcomeSources;
      case BootstrapDestination.chooseSource:
        return AppRoutePaths.welcomeSourceSelect;
      case BootstrapDestination.home:
        return AppRoutePaths.home;
      case null:
        return null;
    }
  }

  void _onAuthResolutionTimeout() {
    if (_authResolved) return;
    _authResolved = true;
    _isAuthenticated = _authRepository.currentSession != null;
    logger.warn(
      'LaunchRedirectGuard auth unresolved after '
      '${_authResolveTimeout.inSeconds}s, fallback to auth state',
    );
    _safeNotify();
  }

  void _safeNotify() {
    if (_pendingNotify) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    final inBuild = phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.transientCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks;
    if (inBuild) {
      _pendingNotify = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _pendingNotify = false;
        notifyListeners();
      });
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _removeAppStateListener();
    _authSubscription.cancel();
    _authResolutionTimer?.cancel();
    _launchRegistry.removeListener(_onLaunchStateChanged);
    super.dispose();
  }
}
