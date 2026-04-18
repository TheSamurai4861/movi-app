import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
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
import 'package:movi/src/features/auth/presentation/auth_otp_page.dart';
import 'package:movi/src/features/auth/presentation/auth_forgot_password_controller.dart';
import 'package:movi/src/features/auth/presentation/auth_forgot_password_page.dart';
import 'package:movi/src/features/auth/presentation/auth_password_page.dart';
import 'package:movi/src/features/auth/presentation/auth_update_password_page.dart';
import 'package:movi/src/features/welcome/domain/enum.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('routes /auth/otp?mode=otp to legacy OTP screen', (tester) async {
    final authRepository = _FakeAuthRepository();
    sl.registerSingleton<AuthRepository>(authRepository);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    addTearDown(authRepository.dispose);

    final router = GoRouter(
      initialLocation: '${AppRoutePaths.authOtp}?mode=otp',
      routes: [
        GoRoute(
          path: AppRoutePaths.authOtp,
          builder: (context, state) {
            final returnOnSuccess =
                state.uri.queryParameters['return_to'] == 'previous';
            final useOtpFallback = state.uri.queryParameters['mode'] == 'otp';
            return useOtpFallback
                ? AuthOtpPage(
                    returnOnSuccess: returnOnSuccess,
                    showPasswordFallback: true,
                  )
                : AuthPasswordPage(returnOnSuccess: returnOnSuccess);
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuthOtpPage), findsOneWidget);
    expect(find.byType(AuthPasswordPage), findsNothing);
    expect(find.text('Use password instead'), findsOneWidget);
  });

  testWidgets('forgot password flow opens dedicated page and sends reset', (
    tester,
  ) async {
    final authRepository = _FakeAuthRepository();
    sl.registerSingleton<AuthRepository>(authRepository);

    String? capturedEmail;
    final container = ProviderContainer(
      overrides: [
        authForgotPasswordResetSenderProvider.overrideWithValue((email) async {
          capturedEmail = email;
        }),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(authRepository.dispose);

    final router = GoRouter(
      initialLocation: AppRoutePaths.authOtp,
      routes: [
        GoRoute(
          path: AppRoutePaths.authOtp,
          builder: (context, state) =>
              const AuthPasswordPage(returnOnSuccess: false),
        ),
        GoRoute(
          path: AppRoutePaths.authForgotPassword,
          builder: (context, state) => const AuthForgotPasswordPage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.byType(AuthForgotPasswordPage), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).first,
      'reset@example.com',
    );
    await tester.tap(find.text('Send link'));
    await tester.pumpAndSettle();

    expect(capturedEmail, 'reset@example.com');
    expect(find.text('Password reset email sent.'), findsOneWidget);
  });

  testWidgets(
    'forgot password remains reachable when launch guard is active',
    (tester) async {
      final authRepository = _FakeAuthRepository.unauthenticatedResolved();
      sl.registerSingleton<AuthRepository>(authRepository);

      final localePreferences = _MemoryLocalePreferences();
      sl.registerSingleton<LocalePreferences>(localePreferences);

      final launchRegistry = AppLaunchStateRegistry(
        initial: const AppLaunchState(
          status: AppLaunchStatus.success,
          destination: BootstrapDestination.auth,
        ),
      );
      final tunnelStateRegistry = TunnelStateRegistry(
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
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);
      addTearDown(authRepository.dispose);
      addTearDown(localePreferences.dispose);

      final appStateController = container.read(appStateControllerProvider);
      final guard = LaunchRedirectGuard(
        logger: _MemoryLogger(),
        appStateController: appStateController,
        authRepository: authRepository,
        launchRegistry: launchRegistry,
        tunnelStateRegistry: tunnelStateRegistry,
        enableEntryJourneyStateModelV2: true,
        enableEntryJourneyRoutingV2: true,
      );
      addTearDown(guard.dispose);

      final router = GoRouter(
        initialLocation: AppRoutePaths.authOtp,
        refreshListenable: guard,
        redirect: guard.handle,
        routes: [
          GoRoute(
            path: AppRoutePaths.launch,
            builder: (context, state) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: AppRoutePaths.authOtp,
            builder: (context, state) =>
                const AuthPasswordPage(returnOnSuccess: false),
          ),
          GoRoute(
            path: AppRoutePaths.authForgotPassword,
            builder: (context, state) => const AuthForgotPasswordPage(),
          ),
          GoRoute(
            path: AppRoutePaths.authUpdatePassword,
            builder: (context, state) => const AuthUpdatePasswordPage(),
          ),
          GoRoute(
            path: AppRoutePaths.authUpdatePasswordCallback,
            builder: (context, state) => const SizedBox.shrink(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AuthPasswordPage), findsOneWidget);

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(find.byType(AuthForgotPasswordPage), findsOneWidget);
      expect(find.byType(AuthPasswordPage), findsNothing);
    },
  );

  testWidgets(
    'forgot password keeps neutral success notice when reset sender fails',
    (tester) async {
      final authRepository = _FakeAuthRepository();
      sl.registerSingleton<AuthRepository>(authRepository);

      final container = ProviderContainer(
        overrides: [
          authForgotPasswordResetSenderProvider.overrideWithValue((
            email,
          ) async {
            throw Exception('backend_failure');
          }),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(authRepository.dispose);

      final router = GoRouter(
        initialLocation: AppRoutePaths.authOtp,
        routes: [
          GoRoute(
            path: AppRoutePaths.authOtp,
            builder: (context, state) =>
                const AuthPasswordPage(returnOnSuccess: false),
          ),
          GoRoute(
            path: AppRoutePaths.authForgotPassword,
            builder: (context, state) => const AuthForgotPasswordPage(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(find.byType(AuthForgotPasswordPage), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        'reset@example.com',
      );
      await tester.tap(find.text('Send link'));
      await tester.pumpAndSettle();

      expect(find.text('Password reset email sent.'), findsOneWidget);
      expect(find.text('backend_failure'), findsNothing);
    },
  );

  testWidgets('password/otp fallback keeps return_to=previous behaviour', (
    tester,
  ) async {
    final authRepository = _FakeAuthRepository();
    sl.registerSingleton<AuthRepository>(authRepository);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    addTearDown(authRepository.dispose);

    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.push(
                  '${AppRoutePaths.authOtp}?return_to=previous&mode=otp',
                ),
                child: const Text('Open auth'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutePaths.authOtp,
          builder: (context, state) {
            final returnOnSuccess =
                state.uri.queryParameters['return_to'] == 'previous';
            final useOtpFallback = state.uri.queryParameters['mode'] == 'otp';
            return useOtpFallback
                ? AuthOtpPage(
                    returnOnSuccess: returnOnSuccess,
                    showPasswordFallback: true,
                  )
                : AuthPasswordPage(returnOnSuccess: returnOnSuccess);
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open auth'));
    await tester.pumpAndSettle();
    expect(find.byType(AuthOtpPage), findsOneWidget);

    await tester.tap(find.text('Use password instead'));
    await tester.pumpAndSettle();
    expect(find.byType(AuthPasswordPage), findsOneWidget);

    authRepository.setAuthenticated();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Open auth'), findsOneWidget);
    expect(find.byType(AuthPasswordPage), findsNothing);
    expect(find.byType(AuthOtpPage), findsNothing);
  });

  testWidgets('routes /auth/update-password to recovery target page', (
    tester,
  ) async {
    final authRepository = _FakeAuthRepository();
    sl.registerSingleton<AuthRepository>(authRepository);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    addTearDown(authRepository.dispose);

    final router = GoRouter(
      initialLocation: AppRoutePaths.authUpdatePassword,
      routes: [
        GoRoute(
          path: AppRoutePaths.authUpdatePassword,
          builder: (context, state) => const AuthUpdatePasswordPage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuthUpdatePasswordPage), findsOneWidget);
  });

  testWidgets('routes /auth/forgot-password to dedicated page', (tester) async {
    final authRepository = _FakeAuthRepository();
    sl.registerSingleton<AuthRepository>(authRepository);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    addTearDown(authRepository.dispose);

    final router = GoRouter(
      initialLocation: AppRoutePaths.authForgotPassword,
      routes: [
        GoRoute(
          path: AppRoutePaths.authForgotPassword,
          builder: (context, state) => const AuthForgotPasswordPage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuthForgotPasswordPage), findsOneWidget);
  });

  testWidgets('update-password page shows field validation errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AuthUpdatePasswordPage(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Mettre a jour'));
    await tester.tap(find.text('Mettre a jour'));
    await tester.pumpAndSettle();

    expect(
      find.text('Veuillez saisir un nouveau mot de passe.'),
      findsOneWidget,
    );
    expect(find.text('Veuillez confirmer le mot de passe.'), findsOneWidget);
    expect(find.text('Corrigez les champs puis reessayez.'), findsOneWidget);
  });

  testWidgets('update-password page toggles visibility and reaches success', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authUpdatePasswordSubmitterProvider.overrideWithValue(
            (password) async {},
          ),
        ],
        child: const MaterialApp(
          home: AuthUpdatePasswordPage(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));

    final firstFieldBefore = tester.widget<EditableText>(
      find.byType(EditableText).at(0),
    );
    expect(firstFieldBefore.obscureText, isTrue);

    await tester.ensureVisible(find.byType(TextFormField).first);
    await tester.tap(find.byIcon(Icons.visibility_outlined).first);
    await tester.pumpAndSettle();

    final firstFieldAfter = tester.widget<EditableText>(
      find.byType(EditableText).at(0),
    );
    expect(firstFieldAfter.obscureText, isFalse);

    await tester.enterText(find.byType(TextFormField).at(0), 'password123');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.ensureVisible(find.text('Mettre a jour'));
    await tester.tap(find.text('Mettre a jour'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      find.text('Mot de passe mis a jour. Vous pouvez vous reconnecter.'),
      findsOneWidget,
    );
  });

  testWidgets('update-password page shows recovery-expired style message', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authUpdatePasswordSubmitterProvider.overrideWithValue((
            password,
          ) async {
            throw Exception('session expired');
          }),
        ],
        child: const MaterialApp(
          home: AuthUpdatePasswordPage(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'password123');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.ensureVisible(find.text('Mettre a jour'));
    await tester.tap(find.text('Mettre a jour'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Le lien de recuperation est invalide ou expire. Demandez un nouveau lien.',
      ),
      findsOneWidget,
    );
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository();

  _FakeAuthRepository.unauthenticatedResolved() {
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

  void setAuthenticated() {
    _session = const AuthSession(userId: 'cloud-user');
    _controller.add(
      AuthSnapshot(status: AuthStatus.authenticated, session: _session),
    );
  }

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
