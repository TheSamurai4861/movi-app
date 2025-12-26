import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/auth/domain/entities/auth_models.dart';
import 'package:movi/src/core/auth/domain/repositories/auth_repository.dart';
import 'package:movi/src/core/di/di.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final sl = ref.watch(slProvider);
  return sl<AuthRepository>();
});

@immutable
class AuthControllerState {
  const AuthControllerState({
    required this.status,
    this.userId,
  });

  final AuthStatus status;
  final String? userId;

  static const AuthControllerState unknown =
      AuthControllerState(status: AuthStatus.unknown);

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

  @override
  AuthControllerState build() {
    final repo = ref.watch(authRepositoryProvider);

    // If the repo changes (hot reload / DI replacement), resubscribe safely.
    if (!identical(_repo, repo)) {
      unawaited(_sub?.cancel() ?? Future.value());
      _repo = repo;
      _sub = repo.onAuthStateChange.listen(_onAuthSnapshot);
    }

    if (!_disposeHookRegistered) {
      _disposeHookRegistered = true;
      ref.onDispose(() {
        unawaited(_sub?.cancel() ?? Future.value());
        _sub = null;
        _repo = null;
      });
    }

    final current = repo.currentSession;
    if (current == null) {
      return const AuthControllerState(status: AuthStatus.unauthenticated);
    }

    return AuthControllerState(
      status: AuthStatus.authenticated,
      userId: current.userId,
    );
  }

  void _onAuthSnapshot(AuthSnapshot snapshot) {
    state = AuthControllerState(
      status: snapshot.status,
      userId: snapshot.userId,
    );
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
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
