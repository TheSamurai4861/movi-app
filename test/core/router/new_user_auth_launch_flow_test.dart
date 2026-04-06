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
    'new user traverses launch, auth, welcome, sources loading, then home',
    (tester) async {
      final localePreferences = _MemoryLocalePreferences();
      final authRepository = _ScriptedAuthRepository.unauthenticatedResolved();
      final logger = _MemoryLogger();
      final launchRegistry = AppLaunchStateRegistry();

      sl.registerSingleton<LocalePreferences>(localePreferences);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      addTearDown(localePreferences.dispose);
      addTearDown(authRepository.dispose);

      final appStateController = container.read(appStateControllerProvider);
      final routeHistory = <String>[];
      final stateHistory = <String>[];
      final launchRunner = _ScriptedLaunchRunner(
        registry: launchRegistry,
        stateHistory: stateHistory,
        scriptedDestinations: <BootstrapDestination>[
          BootstrapDestination.auth,
          BootstrapDestination.welcomeUser,
          BootstrapDestination.welcomeSources,
        ],
      );

      final guard = LaunchRedirectGuard(
        logger: logger,
        appStateController: appStateController,
        authRepository: authRepository,
        launchRegistry: launchRegistry,
      );
      addTearDown(guard.dispose);

      final router = GoRouter(
        initialLocation: AppRoutePaths.launch,
        refreshListenable: guard,
        redirect: guard.handle,
        routes: [
          GoRoute(
            path: AppRoutePaths.launch,
            builder: (context, state) => _TrackedStepPage(
              route: AppRoutePaths.launch,
              label: 'Launch',
              history: routeHistory,
              onEnter: () => launchRunner.runNext(),
            ),
          ),
          GoRoute(
            path: AppRoutePaths.authOtp,
            builder: (context, state) => _TrackedStepPage(
              route: AppRoutePaths.authOtp,
              label: 'Auth OTP',
              history: routeHistory,
              child: ElevatedButton(
                key: const Key('complete-otp'),
                onPressed: () {
                  stateHistory.add('auth:verified');
                  authRepository.setAuthenticated();
                  context.go(AppRoutePaths.launch);
                },
                child: const Text('Complete OTP'),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutePaths.bootstrap,
            builder: (context, state) => _TrackedStepPage(
              route: AppRoutePaths.bootstrap,
              label: 'Bootstrap',
              history: routeHistory,
            ),
          ),
          GoRoute(
            path: AppRoutePaths.welcomeUser,
            builder: (context, state) => _TrackedStepPage(
              route: AppRoutePaths.welcomeUser,
              label: 'Welcome User',
              history: routeHistory,
              child: ElevatedButton(
                key: const Key('create-profile'),
                onPressed: () {
                  stateHistory.add('welcomeUser:createProfile');
                  launchRunner.resetToIdle();
                  context.go(AppRoutePaths.bootstrap);
                },
                child: const Text('Create profile'),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutePaths.welcomeSources,
            builder: (context, state) => _TrackedStepPage(
              route: AppRoutePaths.welcomeSources,
              label: 'Welcome Sources',
              history: routeHistory,
              child: ElevatedButton(
                key: const Key('activate-source'),
                onPressed: () {
                  stateHistory.add('welcomeSources:activateSource');
                  context.go(AppRoutePaths.welcomeSourceLoading);
                },
                child: const Text('Activate source'),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutePaths.welcomeSourceLoading,
            builder: (context, state) => _TrackedStepPage(
              route: AppRoutePaths.welcomeSourceLoading,
              label: 'Welcome Source Loading',
              history: routeHistory,
              onEnter: () {
                stateHistory.add('welcomeSourceLoading:homeReady');
                appStateController.setActiveIptvSources({'source-1'});
                launchRegistry.update(
                  AppLaunchState(
                    status: AppLaunchStatus.success,
                    phase: AppLaunchPhase.done,
                    destination: BootstrapDestination.home,
                    criteria: const AppLaunchCriteria(
                      hasSession: true,
                      hasSelectedProfile: true,
                      hasSelectedSource: true,
                      hasIptvCatalogReady: true,
                      hasHomePreloaded: true,
                      hasLibraryReady: true,
                    ),
                  ),
                );
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!context.mounted) return;
                  context.go(AppRoutePaths.home);
                });
              },
            ),
          ),
          GoRoute(
            path: AppRoutePaths.home,
            builder: (context, state) => _TrackedStepPage(
              route: AppRoutePaths.home,
              label: 'Home',
              history: routeHistory,
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Auth OTP'), findsOneWidget);
      expect(
        routeHistory,
        <String>[AppRoutePaths.launch, AppRoutePaths.authOtp],
      );
      expect(stateHistory, <String>['launch:auth']);

      await tester.tap(find.byKey(const Key('complete-otp')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Welcome User'), findsOneWidget);
      expect(
        routeHistory,
        <String>[
          AppRoutePaths.launch,
          AppRoutePaths.authOtp,
          AppRoutePaths.launch,
          AppRoutePaths.welcomeUser,
        ],
      );
      expect(
        stateHistory,
        <String>['launch:auth', 'auth:verified', 'launch:welcomeUser'],
      );

      await tester.tap(find.byKey(const Key('create-profile')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Welcome Sources'), findsOneWidget);
      expect(
        routeHistory,
        <String>[
          AppRoutePaths.launch,
          AppRoutePaths.authOtp,
          AppRoutePaths.launch,
          AppRoutePaths.welcomeUser,
          AppRoutePaths.launch,
          AppRoutePaths.welcomeSources,
        ],
      );
      expect(
        stateHistory,
        <String>[
          'launch:auth',
          'auth:verified',
          'launch:welcomeUser',
          'welcomeUser:createProfile',
          'launch:resetToIdle',
          'launch:welcomeSources',
        ],
      );

      await tester.tap(find.byKey(const Key('activate-source')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        routeHistory,
        <String>[
          AppRoutePaths.launch,
          AppRoutePaths.authOtp,
          AppRoutePaths.launch,
          AppRoutePaths.welcomeUser,
          AppRoutePaths.launch,
          AppRoutePaths.welcomeSources,
          AppRoutePaths.welcomeSourceLoading,
          AppRoutePaths.home,
        ],
      );
      expect(
        stateHistory,
        <String>[
          'launch:auth',
          'auth:verified',
          'launch:welcomeUser',
          'welcomeUser:createProfile',
          'launch:resetToIdle',
          'launch:welcomeSources',
          'welcomeSources:activateSource',
          'welcomeSourceLoading:homeReady',
        ],
      );
      expect(appStateController.activeIptvSourceIds, {'source-1'});
    },
  );
}

class _TrackedStepPage extends StatefulWidget {
  const _TrackedStepPage({
    required this.route,
    required this.label,
    required this.history,
    this.onEnter,
    this.child,
  });

  final String route;
  final String label;
  final List<String> history;
  final VoidCallback? onEnter;
  final Widget? child;

  @override
  State<_TrackedStepPage> createState() => _TrackedStepPageState();
}

class _TrackedStepPageState extends State<_TrackedStepPage> {
  @override
  void initState() {
    super.initState();
    widget.history.add(widget.route);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onEnter?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.label),
            if (widget.child != null) ...[
              const SizedBox(height: 16),
              widget.child!,
            ],
          ],
        ),
      ),
    );
  }
}

class _ScriptedLaunchRunner {
  _ScriptedLaunchRunner({
    required this.registry,
    required this.stateHistory,
    required List<BootstrapDestination> scriptedDestinations,
  }) : _scriptedDestinations = List<BootstrapDestination>.from(
         scriptedDestinations,
       );

  final AppLaunchStateRegistry registry;
  final List<String> stateHistory;
  final List<BootstrapDestination> _scriptedDestinations;

  void runNext() {
    if (_scriptedDestinations.isEmpty) {
      return;
    }

    final next = _scriptedDestinations.removeAt(0);
    stateHistory.add('launch:${next.name}');

    registry.update(
      const AppLaunchState(
        status: AppLaunchStatus.running,
        phase: AppLaunchPhase.startup,
      ),
    );

    Future<void>.microtask(() {
      registry.update(
        AppLaunchState(
          status: AppLaunchStatus.success,
          phase: AppLaunchPhase.done,
          destination: next,
        ),
      );
    });
  }

  void resetToIdle() {
    stateHistory.add('launch:resetToIdle');
    registry.update(const AppLaunchState());
  }
}

class _ScriptedAuthRepository implements AuthRepository {
  _ScriptedAuthRepository.unauthenticatedResolved() {
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

  void setAuthenticated() {
    _session = const AuthSession(userId: 'cloud-user');
    _controller.add(
      AuthSnapshot(status: AuthStatus.authenticated, session: _session),
    );
  }

  @override
  Future<AuthSession?> refreshSession() async => _session;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    setAuthenticated();
  }

  @override
  Future<void> signInWithOtp({
    required String email,
    bool shouldCreateUser = true,
  }) async {}

  @override
  Future<bool> verifyOtp({required String email, required String token}) async {
    setAuthenticated();
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
