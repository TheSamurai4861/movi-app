import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/auth/application/auth_orchestrator.dart';
import 'package:movi/src/core/auth/application/ports/local_cleanup_port.dart';
import 'package:movi/src/core/auth/domain/entities/auth_models.dart';
import 'package:movi/src/core/auth/domain/repositories/auth_repository.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/auth/application/services/local_data_cleanup_service.dart';
import 'package:movi/src/core/auth/application/ports/auth_telemetry_port.dart';
import 'package:movi/src/core/auth/infrastructure/auth_telemetry_adapters.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/core/preferences/selected_profile_preferences.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/core/startup/app_launch_orchestrator.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final sl = ref.watch(slProvider);
  return sl<AuthRepository>();
});

final authOrchestratorProvider = Provider<AuthOrchestrator>((ref) {
  final sl = ref.watch(slProvider);
  final repo = ref.watch(authRepositoryProvider);
  final cleanupService = sl.isRegistered<LocalDataCleanupService>()
      ? sl<LocalDataCleanupService>()
      : null;
  final LocalCleanupPort? cleanupPort = cleanupService == null
      ? null
      : _LocalCleanupAdapter(cleanupService);
  final AppLogger? logger = sl.isRegistered<AppLogger>()
      ? sl<AppLogger>()
      : null;
  final AuthTelemetryPort telemetry = AuthLoggerTelemetryAdapter(
    logger: logger,
  );

  return AuthOrchestrator(
    repository: repo,
    cleanupPort: cleanupPort,
    telemetry: telemetry,
  );
});

final class _LocalCleanupAdapter implements LocalCleanupPort {
  _LocalCleanupAdapter(this._service);
  final LocalDataCleanupService _service;

  @override
  Future<void> clearSensitiveSessionState() =>
      _service.clearSensitiveSessionState();

  @override
  Future<void> clearAllLocalData() => _service.clearAllLocalData();
}

@immutable
class AuthControllerState {
  const AuthControllerState({required this.status, this.userId});

  final AuthStatus status;
  final String? userId;

  static const AuthControllerState unknown = AuthControllerState(
    status: AuthStatus.unknown,
  );

  static const _sentinel = Object();

  /// copyWith that also allows *forcing* userId to null.
  AuthControllerState copyWith({
    AuthStatus? status,
    Object? userId = _sentinel,
  }) {
    return AuthControllerState(
      status: status ?? this.status,
      userId: identical(userId, _sentinel) ? this.userId : userId as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AuthControllerState &&
        other.status == status &&
        other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(status, userId);
}

class AuthController extends Notifier<AuthControllerState> {
  StreamSubscription<AuthSnapshot>? _sub;
  AuthRepository? _repo;
  bool _disposeHookRegistered = false;
  bool _bootstrapped = false;
  bool _isBuilding = false;
  AuthControllerState _currentState = AuthControllerState.unknown;
  Future<void>? _sessionResetInFlight;

  @override
  AuthControllerState build() {
    _isBuilding = true;
    try {
      final sl = ref.watch(slProvider);
      final repo = ref.watch(authRepositoryProvider);
      final orchestrator = ref.watch(authOrchestratorProvider);
      final launchRegistry = sl.isRegistered<AppLaunchStateRegistry>()
          ? sl<AppLaunchStateRegistry>()
          : null;
      final repoChanged = !identical(_repo, repo);

      // If the repo changes (hot reload / DI replacement), resubscribe safely.
      if (repoChanged) {
        unawaited(_sub?.cancel() ?? Future.value());
        _repo = repo;
        _sub = null;
        _bootstrapped = false;
      }

      if (!_disposeHookRegistered) {
        _disposeHookRegistered = true;
        ref.onDispose(() {
          unawaited(_sub?.cancel() ?? Future.value());
          _sub = null;
          _repo = null;
        });
      }

      // Bootstrapping: explicit unknown -> authenticated/unauthenticated.
      if (!_bootstrapped) {
        _bootstrapped = true;
        final launchSnapshot = _snapshotFromResolvedLaunch(
          launchRegistry?.state,
          repo,
        );
        if (launchSnapshot != null) {
          _setResolvedState(_stateFromSnapshot(launchSnapshot));
        } else {
          _setResolvedState(AuthControllerState.unknown);
          unawaited(() async {
            final result = await orchestrator.bootstrapSession();
            _onAuthSnapshot(result.snapshot);
          }());
        }
      }

      if (repoChanged) {
        _sub = repo.onAuthStateChange.listen(_onAuthSnapshot);
      }

      return _currentState;
    } finally {
      _isBuilding = false;
    }
  }

  void _onAuthSnapshot(AuthSnapshot snapshot) {
    final previous = _currentState;
    final hadAuthenticatedUser =
        previous.status == AuthStatus.authenticated &&
        previous.userId != null &&
        previous.userId!.trim().isNotEmpty;
    final hasLostSession =
        hadAuthenticatedUser && snapshot.status == AuthStatus.unauthenticated;
    final hasSwitchedUser =
        hadAuthenticatedUser &&
        snapshot.status == AuthStatus.authenticated &&
        snapshot.userId != null &&
        snapshot.userId!.trim().isNotEmpty &&
        snapshot.userId != previous.userId;

    if (hasLostSession || hasSwitchedUser) {
      unawaited(
        _resetSessionDerivedStateBestEffort(
          reason: hasSwitchedUser ? 'auth_user_changed' : 'auth_session_lost',
        ),
      );
    }

    _setResolvedState(_stateFromSnapshot(snapshot));
  }

  Future<void> _resetSessionDerivedStateBestEffort({
    required String reason,
  }) {
    final ongoing = _sessionResetInFlight;
    if (ongoing != null) {
      return ongoing;
    }

    final future = () async {
      ref.read(appStateControllerProvider).setActiveIptvSources(<String>{});

      final locator = ref.read(slProvider);
      if (locator.isRegistered<SelectedIptvSourcePreferences>()) {
        try {
          await locator<SelectedIptvSourcePreferences>().clear();
        } catch (error) {
          if (kDebugMode) {
            debugPrint(
              '[AuthController] Failed to clear selected IPTV source '
              '(reason=$reason): $error',
            );
          }
        }
      }

      if (locator.isRegistered<SelectedProfilePreferences>()) {
        try {
          await locator<SelectedProfilePreferences>().clear();
        } catch (error) {
          if (kDebugMode) {
            debugPrint(
              '[AuthController] Failed to clear selected profile '
              '(reason=$reason): $error',
            );
          }
        }
      }
    }();

    late final Future<void> trackedFuture;
    trackedFuture = future.whenComplete(() {
      if (identical(_sessionResetInFlight, trackedFuture)) {
        _sessionResetInFlight = null;
      }
    });
    _sessionResetInFlight = trackedFuture;
    return trackedFuture;
  }

  AuthSnapshot? _snapshotFromResolvedLaunch(
    AppLaunchState? launchState,
    AuthRepository repo,
  ) {
    if (launchState == null || launchState.status != AppLaunchStatus.success) {
      return null;
    }

    if (!launchState.criteria.hasSession) {
      return AuthSnapshot.unauthenticated;
    }

    final session = repo.currentSession;
    if (session == null) {
      return null;
    }

    return AuthSnapshot(status: AuthStatus.authenticated, session: session);
  }

  Future<void> signOut() async {
    final orchestrator = ref.read(authOrchestratorProvider);
    await orchestrator.signOutAndCleanup();
  }

  AuthControllerState _stateFromSnapshot(AuthSnapshot snapshot) {
    return AuthControllerState(
      status: snapshot.status,
      userId: snapshot.userId,
    );
  }

  void _setResolvedState(AuthControllerState next) {
    _currentState = next;
    if (!_isBuilding) {
      state = next;
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthControllerState>(AuthController.new);

final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authControllerProvider).status;
});

final authUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authControllerProvider).userId;
});
