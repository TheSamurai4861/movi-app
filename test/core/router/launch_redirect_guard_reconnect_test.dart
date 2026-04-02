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
import 'package:movi/src/core/startup/app_launch_criteria.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/features/welcome/domain/enum.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
    'keeps /auth/otp?return_to=previous reachable even when launch state is already successful',
    (tester) async {
      final localePreferences = _MemoryLocalePreferences();
      final authRepository = _FakeAuthRepository.authenticated();
      final logger = _MemoryLogger();
      final launchRegistry = AppLaunchStateRegistry(
        initial: const AppLaunchState(
          status: AppLaunchStatus.success,
          destination: BootstrapDestination.home,
        ),
      );

      sl.registerSingleton<LocalePreferences>(localePreferences);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      addTearDown(authRepository.dispose);
      addTearDown(localePreferences.dispose);

      final appStateController = container.read(appStateControllerProvider);
      final guard = LaunchRedirectGuard(
        logger: logger,
        appStateController: appStateController,
        authRepository: authRepository,
        launchRegistry: launchRegistry,
      );
      addTearDown(guard.dispose);

      final router = GoRouter(
        initialLocation: '${AppRoutePaths.authOtp}?return_to=previous',
        refreshListenable: guard,
        redirect: guard.handle,
        routes: [
          GoRoute(
            path: AppRoutePaths.launch,
            builder: (context, state) => const Text('Launch'),
          ),
          GoRoute(
            path: AppRoutePaths.home,
            builder: (context, state) => const Text('Home'),
          ),
          GoRoute(
            path: AppRoutePaths.bootstrap,
            builder: (context, state) => const Text('Bootstrap'),
          ),
          GoRoute(
            path: AppRoutePaths.authOtp,
            builder: (context, state) => const Text('Reconnect Auth'),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reconnect Auth'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
      expect(find.text('Bootstrap'), findsNothing);
    },
  );

  testWidgets(
    'keeps critical routes on bootstrap when destination home is not really ready',
    (tester) async {
      final localePreferences = _MemoryLocalePreferences();
      final authRepository = _FakeAuthRepository.authenticated();
      final logger = _MemoryLogger();
      final launchRegistry = AppLaunchStateRegistry(
        initial: const AppLaunchState(
          status: AppLaunchStatus.success,
          destination: BootstrapDestination.home,
          criteria: AppLaunchCriteria(
            hasSession: true,
            hasSelectedProfile: true,
            hasSelectedSource: true,
            hasIptvCatalogReady: true,
            hasHomePreloaded: true,
            hasLibraryReady: false,
          ),
        ),
      );

      sl.registerSingleton<LocalePreferences>(localePreferences);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      addTearDown(authRepository.dispose);
      addTearDown(localePreferences.dispose);

      final appStateController = container.read(appStateControllerProvider);
      final guard = LaunchRedirectGuard(
        logger: logger,
        appStateController: appStateController,
        authRepository: authRepository,
        launchRegistry: launchRegistry,
      );
      addTearDown(guard.dispose);

      final router = GoRouter(
        initialLocation: AppRoutePaths.bootstrap,
        refreshListenable: guard,
        redirect: guard.handle,
        routes: [
          GoRoute(
            path: AppRoutePaths.launch,
            builder: (context, state) => const Text('Launch'),
          ),
          GoRoute(
            path: AppRoutePaths.home,
            builder: (context, state) => const Text('Home'),
          ),
          GoRoute(
            path: AppRoutePaths.bootstrap,
            builder: (context, state) => const Text('Bootstrap'),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bootstrap'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    },
  );
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository.authenticated()
    : _session = const AuthSession(userId: 'cloud-user');

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
