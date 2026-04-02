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
  final AppLogger? logger =
      sl.isRegistered<AppLogger>() ? sl<AppLogger>() : null;
  final AuthTelemetryPort telemetry = AuthLoggerTelemetryAdapter(logger: logger);

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

  @override
  AuthControllerState build() {
    final repo = ref.watch(authRepositoryProvider);
    final orchestrator = ref.watch(authOrchestratorProvider);

    // If the repo changes (hot reload / DI replacement), resubscribe safely.
    if (!identical(_repo, repo)) {
      unawaited(_sub?.cancel() ?? Future.value());
      _repo = repo;
      _sub = repo.onAuthStateChange.listen(_onAuthSnapshot);
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
      state = AuthControllerState.unknown;
      unawaited(() async {
        final snapshot = await orchestrator.bootstrapSession();
        _onAuthSnapshot(snapshot);
      }());
    }

    return state;
  }

  void _onAuthSnapshot(AuthSnapshot snapshot) {
    state = AuthControllerState(
      status: snapshot.status,
      userId: snapshot.userId,
    );
  }

  Future<void> signOut() async {
    final orchestrator = ref.read(authOrchestratorProvider);
    await orchestrator.signOutAndCleanup();
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
