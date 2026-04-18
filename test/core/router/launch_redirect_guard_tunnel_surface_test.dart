import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/core/auth/domain/entities/auth_models.dart';
import 'package:movi/src/core/auth/domain/repositories/auth_repository.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/core/router/app_route_paths.dart';
import 'package:movi/src/core/router/launch_redirect_guard.dart';
import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/core/startup/domain/tunnel_state.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/features/welcome/domain/enum.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
    'redirects startup routes to auth from projected tunnel surface',
    (tester) async {
      final harness = _GuardHarness(
        authRepository: _FakeAuthRepository.unauthenticatedResolved(),
        tunnelStateRegistry: TunnelStateRegistry(
          initial: const TunnelState(
            stage: TunnelStage.authRequired,
            executionMode: TunnelExecutionMode.cloud,
            loadingState: TunnelLoadingState.completed,
            reasonCode: 'auth_required',
            hasSession: false,
            hasSelectedProfile: false,
            hasSelectedSource: false,
            hasCatalogReady: false,
            hasHomePreloaded: false,
            hasLibraryReady: false,
            profilesCount: 0,
            sourcesCount: 0,
            isShadowMode: false,
            legacyDestination: BootstrapDestination.auth,
          ),
        ),
      );
      addTearDown(harness.dispose);

      final router = harness.createRouter(initialLocation: AppRoutePaths.home);
      addTearDown(router.dispose);

      await tester.pumpWidget(harness.buildApp(router));
      await tester.pumpAndSettle();

      expect(find.text('Auth'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    },
  );

  testWidgets(
    'keeps non-startup routes reachable when projected tunnel is ready for home',
    (tester) async {
      final harness = _GuardHarness(
        authRepository: _FakeAuthRepository.authenticated(),
        tunnelStateRegistry: TunnelStateRegistry(
          initial: const TunnelState(
            stage: TunnelStage.readyForHome,
            executionMode: TunnelExecutionMode.cloud,
            loadingState: TunnelLoadingState.completed,
            reasonCode: 'home_ready',
            hasSession: true,
            hasSelectedProfile: true,
            hasSelectedSource: true,
            hasCatalogReady: true,
            hasHomePreloaded: true,
            hasLibraryReady: true,
            profilesCount: 1,
            sourcesCount: 1,
            isShadowMode: false,
            legacyDestination: BootstrapDestination.home,
          ),
        ),
      );
      addTearDown(harness.dispose);

      final router = harness.createRouter(
        initialLocation: AppRoutePaths.player,
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(harness.buildApp(router));
      await tester.pumpAndSettle();

      expect(find.text('Player'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
      expect(find.text('Auth'), findsNothing);
    },
  );

  testWidgets(
    'keeps auth recovery route reachable from projected auth surface',
    (tester) async {
      final harness = _GuardHarness(
        authRepository: _FakeAuthRepository.unauthenticatedResolved(),
        tunnelStateRegistry: TunnelStateRegistry(
          initial: const TunnelState(
            stage: TunnelStage.authRequired,
            executionMode: TunnelExecutionMode.cloud,
            loadingState: TunnelLoadingState.completed,
            reasonCode: 'auth_required',
            hasSession: false,
            hasSelectedProfile: false,
            hasSelectedSource: false,
            hasCatalogReady: false,
            hasHomePreloaded: false,
            hasLibraryReady: false,
            profilesCount: 0,
            sourcesCount: 0,
            isShadowMode: false,
            legacyDestination: BootstrapDestination.auth,
          ),
        ),
      );
      addTearDown(harness.dispose);

      final router = harness.createRouter(
        initialLocation: AppRoutePaths.authForgotPassword,
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(harness.buildApp(router));
      await tester.pumpAndSettle();

      expect(find.text('Forgot Password'), findsOneWidget);
      expect(find.text('Auth'), findsNothing);
    },
  );

  testWidgets('keeps update-password route reachable', (tester) async {
    final harness = _GuardHarness(
      authRepository: _FakeAuthRepository.unauthenticatedResolved(),
      tunnelStateRegistry: TunnelStateRegistry(
        initial: const TunnelState(
          stage: TunnelStage.authRequired,
          executionMode: TunnelExecutionMode.cloud,
          loadingState: TunnelLoadingState.completed,
          reasonCode: 'auth_required',
          hasSession: false,
          hasSelectedProfile: false,
          hasSelectedSource: false,
          hasCatalogReady: false,
          hasHomePreloaded: false,
          hasLibraryReady: false,
          profilesCount: 0,
          sourcesCount: 0,
          isShadowMode: false,
          legacyDestination: BootstrapDestination.auth,
        ),
      ),
    );
    addTearDown(harness.dispose);

    final updateRouter = harness.createRouter(
      initialLocation: AppRoutePaths.authUpdatePassword,
    );
    addTearDown(updateRouter.dispose);

    await tester.pumpWidget(harness.buildApp(updateRouter));
    await tester.pumpAndSettle();

    expect(find.text('Update Password'), findsOneWidget);
  });

  testWidgets(
    'keeps update-password callback route reachable',
    (tester) async {
      final harness = _GuardHarness(
        authRepository: _FakeAuthRepository.unauthenticatedResolved(),
        tunnelStateRegistry: TunnelStateRegistry(
          initial: const TunnelState(
            stage: TunnelStage.authRequired,
            executionMode: TunnelExecutionMode.cloud,
            loadingState: TunnelLoadingState.completed,
            reasonCode: 'auth_required',
            hasSession: false,
            hasSelectedProfile: false,
            hasSelectedSource: false,
            hasCatalogReady: false,
            hasHomePreloaded: false,
            hasLibraryReady: false,
            profilesCount: 0,
            sourcesCount: 0,
            isShadowMode: false,
            legacyDestination: BootstrapDestination.auth,
          ),
        ),
      );
      addTearDown(harness.dispose);

      final callbackRouter = harness.createRouter(
        initialLocation: AppRoutePaths.authUpdatePasswordCallback,
      );
      addTearDown(callbackRouter.dispose);

      await tester.pumpWidget(harness.buildApp(callbackRouter));
      await tester.pumpAndSettle();

      expect(find.text('Update Password Callback'), findsOneWidget);
    },
  );

  testWidgets('projects source selection route from projected source surface', (
    tester,
  ) async {
    final harness = _GuardHarness(
      authRepository: _FakeAuthRepository.authenticated(),
      tunnelStateRegistry: TunnelStateRegistry(
        initial: const TunnelState(
          stage: TunnelStage.sourceRequired,
          executionMode: TunnelExecutionMode.cloud,
          loadingState: TunnelLoadingState.completed,
          reasonCode: 'source_selection_required',
          hasSession: true,
          hasSelectedProfile: true,
          hasSelectedSource: false,
          hasCatalogReady: false,
          hasHomePreloaded: false,
          hasLibraryReady: false,
          profilesCount: 1,
          sourcesCount: 2,
          isShadowMode: false,
          legacyDestination: BootstrapDestination.chooseSource,
        ),
      ),
    );
    addTearDown(harness.dispose);

    final router = harness.createRouter(initialLocation: AppRoutePaths.launch);
    addTearDown(router.dispose);

    await tester.pumpWidget(harness.buildApp(router));
    await tester.pumpAndSettle();

    expect(find.text('Choose Source'), findsOneWidget);
    expect(find.text('Launch'), findsNothing);
  });

  testWidgets(
    'keeps welcome source loading stable during projected preloading state',
    (tester) async {
      final harness = _GuardHarness(
        authRepository: _FakeAuthRepository.authenticated(),
        tunnelStateRegistry: TunnelStateRegistry(
          initial: const TunnelState(
            stage: TunnelStage.preloadingHome,
            executionMode: TunnelExecutionMode.cloud,
            loadingState: TunnelLoadingState.inProgress,
            reasonCode: 'preloading_home',
            hasSession: true,
            hasSelectedProfile: true,
            hasSelectedSource: true,
            hasCatalogReady: false,
            hasHomePreloaded: false,
            hasLibraryReady: false,
            profilesCount: 1,
            sourcesCount: 1,
            isShadowMode: false,
            legacyDestination: BootstrapDestination.chooseSource,
          ),
        ),
      );
      addTearDown(harness.dispose);

      final router = harness.createRouter(
        initialLocation: AppRoutePaths.welcomeSourceLoading,
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(harness.buildApp(router));
      await tester.pumpAndSettle();

      expect(find.text('Loading'), findsOneWidget);
      expect(find.text('Bootstrap'), findsNothing);
    },
  );
}

final class _GuardHarness {
  _GuardHarness({
    required this.authRepository,
    required this.tunnelStateRegistry,
  }) : localePreferences = _MemoryLocalePreferences(),
       logger = _MemoryLogger(),
       launchRegistry = AppLaunchStateRegistry(),
       container = ProviderContainer();

  final _FakeAuthRepository authRepository;
  final TunnelStateRegistry tunnelStateRegistry;
  final _MemoryLocalePreferences localePreferences;
  final _MemoryLogger logger;
  final AppLaunchStateRegistry launchRegistry;
  final ProviderContainer container;
  final List<LaunchRedirectGuard> _guards = <LaunchRedirectGuard>[];

  Widget buildApp(GoRouter router) {
    return ProviderScope(child: MaterialApp.router(routerConfig: router));
  }

  GoRouter createRouter({required String initialLocation}) {
    if (sl.isRegistered<LocalePreferences>()) {
      sl.unregister<LocalePreferences>();
    }
    sl.registerSingleton<LocalePreferences>(localePreferences);
    final appStateController = container.read(appStateControllerProvider);

    final guard = LaunchRedirectGuard(
      logger: logger,
      appStateController: appStateController,
      authRepository: authRepository,
      launchRegistry: launchRegistry,
      tunnelStateRegistry: tunnelStateRegistry,
      enableEntryJourneyStateModelV2: true,
      enableEntryJourneyRoutingV2: true,
    );
    _guards.add(guard);

    return GoRouter(
      initialLocation: initialLocation,
      refreshListenable: guard,
      redirect: guard.handle,
      routes: [
        GoRoute(
          path: AppRoutePaths.launch,
          builder: (context, state) => const Text('Launch'),
        ),
        GoRoute(
          path: AppRoutePaths.authOtp,
          builder: (context, state) => const Text('Auth'),
        ),
        GoRoute(
          path: AppRoutePaths.authForgotPassword,
          builder: (context, state) => const Text('Forgot Password'),
        ),
        GoRoute(
          path: AppRoutePaths.authUpdatePassword,
          builder: (context, state) => const Text('Update Password'),
        ),
        GoRoute(
          path: AppRoutePaths.authUpdatePasswordCallback,
          builder: (context, state) => const Text('Update Password Callback'),
        ),
        GoRoute(
          path: AppRoutePaths.bootstrap,
          builder: (context, state) => const Text('Bootstrap'),
        ),
        GoRoute(
          path: AppRoutePaths.welcomeUser,
          builder: (context, state) => const Text('Welcome User'),
        ),
        GoRoute(
          path: AppRoutePaths.welcomeSources,
          builder: (context, state) => const Text('Welcome Sources'),
        ),
        GoRoute(
          path: AppRoutePaths.welcomeSourceSelect,
          builder: (context, state) => const Text('Choose Source'),
        ),
        GoRoute(
          path: AppRoutePaths.welcomeSourceLoading,
          builder: (context, state) => const Text('Loading'),
        ),
        GoRoute(
          path: AppRoutePaths.home,
          builder: (context, state) => const Text('Home'),
        ),
        GoRoute(
          path: AppRoutePaths.player,
          builder: (context, state) => const Text('Player'),
        ),
      ],
    );
  }

  Future<void> dispose() async {
    for (final guard in _guards) {
      guard.dispose();
    }
    container.dispose();
    authRepository.dispose();
    await localePreferences.dispose();
  }
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository.authenticated()
    : _session = const AuthSession(userId: 'cloud-user');

  _FakeAuthRepository.unauthenticatedResolved() : _session = null {
    Future<void>.microtask(() {
      if (!_controller.isClosed) {
        _controller.add(AuthSnapshot.unauthenticated);
      }
    });
  }

  final StreamController<AuthSnapshot> _controller =
      StreamController<AuthSnapshot>.broadcast();

  AuthSession? _session;

  @override
  Stream<AuthSnapshot> get onAuthStateChange => _controller.stream;

  @override
  AuthSession? get currentSession => _session;

  @override
  Future<AuthSession?> refreshSession() async => _session;

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
  Future<void> signOut() async {
    _session = null;
    _controller.add(AuthSnapshot.unauthenticated);
  }

  void dispose() {
    _controller.close();
  }
}

class _MemoryLogger implements AppLogger {
  @override
  void debug(String message, {String? category}) {}

  @override
  void info(String message, {String? category}) {}

  @override
  void warn(String message, {String? category}) {}

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void log(
    LogLevel level,
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {}
}

class _MemoryLocalePreferences implements LocalePreferences {
  final StreamController<String> _languageController =
      StreamController<String>.broadcast();
  final StreamController<ThemeMode> _themeController =
      StreamController<ThemeMode>.broadcast();

  String _languageCode = 'en-US';
  ThemeMode _themeMode = ThemeMode.system;

  @override
  String get languageCode => _languageCode;

  @override
  Stream<String> get languageStream => _languageController.stream;

  @override
  Stream<String> get languageStreamWithInitial async* {
    yield _languageCode;
    yield* _languageController.stream;
  }

  @override
  ThemeMode get themeMode => _themeMode;

  @override
  Stream<ThemeMode> get themeStream => _themeController.stream;

  @override
  Stream<ThemeMode> get themeStreamWithInitial async* {
    yield _themeMode;
    yield* _themeController.stream;
  }

  @override
  Future<void> setLanguageCode(String code) async {
    _languageCode = code;
    _languageController.add(code);
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    _themeController.add(mode);
  }

  @override
  Future<void> dispose() async {
    await _languageController.close();
    await _themeController.close();
  }
}
