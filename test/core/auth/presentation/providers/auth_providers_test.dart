import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/auth/domain/entities/auth_models.dart';
import 'package:movi/src/core/auth/domain/repositories/auth_repository.dart';
import 'package:movi/src/core/auth/presentation/providers/auth_providers.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/startup/app_launch_criteria.dart';
import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/features/welcome/domain/enum.dart';

void main() {
  tearDown(() async {
    await sl.reset();
  });

  test(
    'AuthController reuses resolved launch session without a second bootstrap refresh',
    () {
      final authRepository = _FakeAuthRepository(
        session: const AuthSession(userId: 'cloud-user'),
      );
      sl.registerSingleton<AuthRepository>(authRepository);
      sl.registerSingleton<AppLaunchStateRegistry>(
        AppLaunchStateRegistry(
          initial: const AppLaunchState(
            status: AppLaunchStatus.success,
            destination: BootstrapDestination.home,
            criteria: AppLaunchCriteria(
              hasSession: true,
              hasSelectedProfile: true,
              hasSelectedSource: true,
              hasIptvCatalogReady: true,
              hasHomePreloaded: true,
              hasLibraryReady: true,
            ),
          ),
        ),
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(authControllerProvider);

      expect(state.status, AuthStatus.authenticated);
      expect(state.userId, 'cloud-user');
      expect(authRepository.refreshCalls, 0);
    },
  );

  test(
    'AuthController reuses resolved launch unauthenticated state without refresh',
    () {
      final authRepository = _FakeAuthRepository();
      sl.registerSingleton<AuthRepository>(authRepository);
      sl.registerSingleton<AppLaunchStateRegistry>(
        AppLaunchStateRegistry(
          initial: const AppLaunchState(
            status: AppLaunchStatus.success,
            destination: BootstrapDestination.auth,
            criteria: AppLaunchCriteria.empty,
          ),
        ),
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(authControllerProvider);

      expect(state.status, AuthStatus.unauthenticated);
      expect(state.userId, isNull);
      expect(authRepository.refreshCalls, 0);
    },
  );
}

final class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.session});

  final StreamController<AuthSnapshot> _controller =
      StreamController<AuthSnapshot>.broadcast();

  AuthSession? session;
  int refreshCalls = 0;

  @override
  Stream<AuthSnapshot> get onAuthStateChange => _controller.stream;

  @override
  AuthSession? get currentSession => session;

  @override
  Future<AuthSession?> refreshSession() async {
    refreshCalls += 1;
    return session;
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInWithOtp({
    required String email,
    bool shouldCreateUser = true,
  }) async {}

  @override
  Future<bool> verifyOtp({required String email, required String token}) async {
    return true;
  }

  @override
  Future<void> signOut() async {}
}
