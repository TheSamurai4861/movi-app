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
import 'package:movi/src/core/startup/app_launch_criteria.dart';
import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/features/welcome/domain/enum.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
    'keeps welcome source loading visible while orchestrator is running',
    (tester) async {
      final harness = _GuardHarness(
        launchState: const AppLaunchState(
          status: AppLaunchStatus.running,
          phase: AppLaunchPhase.preloadCompleteHome,
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
      expect(find.text('Launch'), findsNothing);
    },
  );

  testWidgets(
    'redirects welcome source loading to source selection when destination requires it',
    (tester) async {
      final harness = _GuardHarness(
        launchState: const AppLaunchState(
          status: AppLaunchStatus.success,
          phase: AppLaunchPhase.done,
          destination: BootstrapDestination.chooseSource,
        ),
      );
      addTearDown(harness.dispose);

      final router = harness.createRouter(
        initialLocation: AppRoutePaths.welcomeSourceLoading,
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(harness.buildApp(router));
      await tester.pumpAndSettle();

      expect(find.text('Choose Source'), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
    },
  );

  testWidgets(
    'opens Home when destination is home and readiness criteria are complete',
    (tester) async {
      final harness = _GuardHarness(
        launchState: const AppLaunchState(
          status: AppLaunchStatus.success,
          phase: AppLaunchPhase.done,
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
      );
      addTearDown(harness.dispose);

      final router = harness.createRouter(
        initialLocation: AppRoutePaths.launch,
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(harness.buildApp(router));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Launch'), findsNothing);
    },
  );

  testWidgets('redirects Home to auth when auth is required', (tester) async {
    final harness = _GuardHarness(
      launchState: const AppLaunchState(
        status: AppLaunchStatus.success,
        phase: AppLaunchPhase.done,
        destination: BootstrapDestination.auth,
      ),
      authRepository: _FakeAuthRepository.unauthenticatedResolved(),
    );
    addTearDown(harness.dispose);

    final router = harness.createRouter(initialLocation: AppRoutePaths.home);
    addTearDown(router.dispose);

    await tester.pumpWidget(harness.buildApp(router));
    await tester.pumpAndSettle();

    expect(find.text('Auth'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets(
    'redirects launch to auth when bootstrap resolved reauth before auth stream resolves',
    (tester) async {
      final authRepository = _FakeAuthRepository.unauthenticatedUnresolved();
      final harness = _GuardHarness(
        launchState: const AppLaunchState(
          status: AppLaunchStatus.success,
          phase: AppLaunchPhase.done,
          destination: BootstrapDestination.auth,
        ),
        authRepository: authRepository,
      );
      addTearDown(harness.dispose);

      final router = harness.createRouter(
        initialLocation: AppRoutePaths.launch,
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(harness.buildApp(router));
      await tester.pump();

      expect(find.text('Auth'), findsOneWidget);
      expect(find.text('Launch'), findsNothing);

      authRepository.emitUnauthenticated();
      await tester.pump();
    },
  );

  testWidgets(
    'redirects Home to profile action page when profile is required',
    (tester) async {
      final harness = _GuardHarness(
        launchState: const AppLaunchState(
          status: AppLaunchStatus.success,
          phase: AppLaunchPhase.done,
          destination: BootstrapDestination.welcomeUser,
        ),
      );
      addTearDown(harness.dispose);

      final router = harness.createRouter(initialLocation: AppRoutePaths.home);
      addTearDown(router.dispose);

      await tester.pumpWidget(harness.buildApp(router));
      await tester.pumpAndSettle();

      expect(find.text('Welcome User'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    },
  );

  testWidgets(
    'keeps Home partial on Home instead of redirecting to source recovery',
    (tester) async {
      final harness = _GuardHarness(
        launchState: const AppLaunchState(
          status: AppLaunchStatus.success,
          phase: AppLaunchPhase.done,
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
      );
      addTearDown(harness.dispose);

      final router = harness.createRouter(initialLocation: AppRoutePaths.home);
      addTearDown(router.dispose);

      await tester.pumpWidget(harness.buildApp(router));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Welcome Sources'), findsNothing);
      expect(find.text('Bootstrap'), findsNothing);
    },
  );

  testWidgets(
    'redirects Home to source selection page when source selection is required',
    (tester) async {
      final harness = _GuardHarness(
        launchState: const AppLaunchState(
          status: AppLaunchStatus.success,
          phase: AppLaunchPhase.done,
          destination: BootstrapDestination.chooseSource,
        ),
      );
      addTearDown(harness.dispose);

      final router = harness.createRouter(initialLocation: AppRoutePaths.home);
      addTearDown(router.dispose);

      await tester.pumpWidget(harness.buildApp(router));
      await tester.pumpAndSettle();

      expect(find.text('Choose Source'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    },
  );

  testWidgets(
    'redirects launch to source selection page when source selection is required',
    (tester) async {
      final harness = _GuardHarness(
        launchState: const AppLaunchState(
          status: AppLaunchStatus.success,
          phase: AppLaunchPhase.done,
          destination: BootstrapDestination.chooseSource,
        ),
      );
      addTearDown(harness.dispose);

      final router = harness.createRouter(
        initialLocation: AppRoutePaths.launch,
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(harness.buildApp(router));
      await tester.pumpAndSettle();

      expect(find.text('Choose Source'), findsOneWidget);
      expect(find.text('Launch'), findsNothing);
    },
  );

  testWidgets(
    'redirects Home to source action page when recovery before Home is required',
    (tester) async {
      final harness = _GuardHarness(
        launchState: const AppLaunchState(
          status: AppLaunchStatus.success,
          phase: AppLaunchPhase.done,
          destination: BootstrapDestination.welcomeSources,
        ),
      );
      addTearDown(harness.dispose);

      final router = harness.createRouter(initialLocation: AppRoutePaths.home);
      addTearDown(router.dispose);

      await tester.pumpWidget(harness.buildApp(router));
      await tester.pumpAndSettle();

      expect(find.text('Welcome Sources'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    },
  );
}

final class _GuardHarness {
  _GuardHarness({
    required AppLaunchState launchState,
    _FakeAuthRepository? authRepository,
  }) : localePreferences = _MemoryLocalePreferences(),
       authRepository = authRepository ?? _FakeAuthRepository.authenticated(),
       logger = _MemoryLogger(),
       launchRegistry = AppLaunchStateRegistry(initial: launchState),
       container = ProviderContainer() {
    sl.registerSingleton<LocalePreferences>(localePreferences);
  }

  final _MemoryLocalePreferences localePreferences;
  final _FakeAuthRepository authRepository;
  final _MemoryLogger logger;
  final AppLaunchStateRegistry launchRegistry;
  final ProviderContainer container;

  Widget buildApp(GoRouter router) {
    return ProviderScope(child: MaterialApp.router(routerConfig: router));
  }

  GoRouter createRouter({required String initialLocation}) {
    final appStateController = container.read(appStateControllerProvider);
    final guard = LaunchRedirectGuard(
      logger: logger,
      appStateController: appStateController,
      authRepository: authRepository,
      launchRegistry: launchRegistry,
    );
    addTearDown(guard.dispose);

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
      ],
    );
  }

  Future<void> dispose() async {
    container.dispose();
    authRepository.dispose();
    await localePreferences.dispose();
  }
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository.authenticated()
    : _session = const AuthSession(userId: 'cloud-user');

  _FakeAuthRepository.unauthenticatedUnresolved() : _session = null;

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

  void emitUnauthenticated() {
    _controller.add(AuthSnapshot.unauthenticated);
  }

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
