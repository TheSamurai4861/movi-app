import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/core/preferences/selected_profile_preferences.dart';

import 'package:movi/src/core/auth/domain/entities/auth_models.dart';
import 'package:movi/src/core/auth/domain/repositories/auth_repository.dart';
import 'package:movi/src/core/auth/presentation/providers/auth_providers.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/state/app_state.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
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

      final container = ProviderContainer(
        overrides: [
          appStateControllerProvider.overrideWithValue(
            _NoopAppStateController(),
          ),
        ],
      );
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

      final container = ProviderContainer(
        overrides: [
          appStateControllerProvider.overrideWithValue(
            _NoopAppStateController(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(authControllerProvider);

      expect(state.status, AuthStatus.unauthenticated);
      expect(state.userId, isNull);
      expect(authRepository.refreshCalls, 0);
    },
  );

  test(
    'AuthController handles an auth stream event emitted during build',
    () {
      final authRepository = _FakeAuthRepository(
        emittedSnapshot: const AuthSnapshot(
          status: AuthStatus.authenticated,
          session: AuthSession(userId: 'stream-user'),
        ),
      );
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

      final container = ProviderContainer(
        overrides: [
          appStateControllerProvider.overrideWith(
            (ref) => _NoopAppStateController(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(authControllerProvider);

      expect(state.status, AuthStatus.authenticated);
      expect(state.userId, 'stream-user');
      expect(authRepository.refreshCalls, 0);
    },
  );

  test(
    'AuthController waits for switched-user cleanup before publishing new auth state',
    () async {
      final authRepository = _FakeAuthRepository(
        session: const AuthSession(userId: 'old-user'),
        emittedSnapshot: const AuthSnapshot(
          status: AuthStatus.authenticated,
          session: AuthSession(userId: 'new-user'),
        ),
      );
      final profilePrefs = _FakeSelectedProfilePreferences(
        clearDelay: const Duration(milliseconds: 40),
      );
      final sourcePrefs = _FakeSelectedIptvSourcePreferences(
        clearDelay: const Duration(milliseconds: 40),
      );
      await profilePrefs.setSelectedProfileId('profile-old');
      await sourcePrefs.setSelectedSourceId('source-old');
      sl.registerSingleton<AuthRepository>(authRepository);
      sl.registerSingleton<SelectedProfilePreferences>(profilePrefs);
      sl.registerSingleton<SelectedIptvSourcePreferences>(sourcePrefs);
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

      final container = ProviderContainer(
        overrides: [
          appStateControllerProvider.overrideWithValue(
            _NoopAppStateController(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final authSub = container.listen<AuthControllerState>(
        authControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(authSub.close);

      final immediate = authSub.read();
      expect(immediate.userId, 'old-user');

      await Future<void>.delayed(const Duration(milliseconds: 160));
      final resolved = authSub.read();
      expect(resolved.userId, 'new-user');
      expect(profilePrefs.clearCalls, 1);
      expect(sourcePrefs.clearCalls, 1);
      expect(profilePrefs.selectedProfileId, isNull);
      expect(sourcePrefs.selectedSourceId, isNull);
    },
  );
}

final class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.session, this.emittedSnapshot});

  final AuthSnapshot? emittedSnapshot;

  AuthSession? session;
  int refreshCalls = 0;

  @override
  Stream<AuthSnapshot> get onAuthStateChange {
    final snapshot = emittedSnapshot;
    if (snapshot == null) {
      return const Stream<AuthSnapshot>.empty();
    }
    late final StreamController<AuthSnapshot> controller;
    controller = StreamController<AuthSnapshot>.broadcast(
      sync: true,
      onListen: () {
        controller.add(snapshot);
        controller.close();
      },
    );
    return controller.stream;
  }

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

final class _FakeSelectedProfilePreferences
    implements SelectedProfilePreferences {
  _FakeSelectedProfilePreferences({this.clearDelay = Duration.zero});

  final Duration clearDelay;
  final StreamController<String?> _controller =
      StreamController<String?>.broadcast();
  int clearCalls = 0;
  String? _selectedProfileId;

  @override
  String? get selectedProfileId => _selectedProfileId;

  @override
  Stream<String?> get selectedProfileIdStream => _controller.stream;

  @override
  Stream<String?> get selectedProfileIdStreamWithInitial async* {
    yield _selectedProfileId;
    yield* _controller.stream;
  }

  @override
  Future<void> clear() async {
    clearCalls += 1;
    if (clearDelay > Duration.zero) {
      await Future<void>.delayed(clearDelay);
    }
    _selectedProfileId = null;
    _controller.add(null);
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  Future<void> setSelectedProfileId(String? profileId) async {
    _selectedProfileId = profileId;
    _controller.add(_selectedProfileId);
  }
}

final class _FakeSelectedIptvSourcePreferences
    implements SelectedIptvSourcePreferences {
  _FakeSelectedIptvSourcePreferences({this.clearDelay = Duration.zero});

  final Duration clearDelay;
  final StreamController<String?> _controller =
      StreamController<String?>.broadcast();
  int clearCalls = 0;
  String? _selectedSourceId;

  @override
  String? get selectedSourceId => _selectedSourceId;

  @override
  Stream<String?> get selectedSourceIdStream => _controller.stream;

  @override
  Stream<String?> get selectedSourceIdStreamWithInitial async* {
    yield _selectedSourceId;
    yield* _controller.stream;
  }

  @override
  Future<void> clear() async {
    clearCalls += 1;
    if (clearDelay > Duration.zero) {
      await Future<void>.delayed(clearDelay);
    }
    _selectedSourceId = null;
    _controller.add(null);
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  Future<void> rereadFromStorage() async {}

  @override
  Future<void> setSelectedSourceId(String? sourceId) async {
    _selectedSourceId = sourceId;
    _controller.add(_selectedSourceId);
  }
}

final class _NoopAppStateController extends AppStateController {
  @override
  AppState build() => AppState();

  @override
  void setActiveIptvSources(Set<String> sourceIds) {}
}
