import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/auth/domain/entities/auth_models.dart';
import 'package:movi/src/core/auth/domain/repositories/auth_repository.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/router/app_route_paths.dart';
import 'package:movi/src/features/auth/presentation/auth_otp_page.dart';
import 'package:movi/src/features/auth/presentation/auth_password_controller.dart';
import 'package:movi/src/features/auth/presentation/auth_password_page.dart';

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

  testWidgets('forgot password sends reset email and shows feedback', (
    tester,
  ) async {
    final authRepository = _FakeAuthRepository();
    sl.registerSingleton<AuthRepository>(authRepository);

    String? capturedEmail;
    final container = ProviderContainer(
      overrides: [
        authPasswordResetSenderProvider.overrideWithValue((email) async {
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

    await tester.enterText(
      find.byType(TextFormField).first,
      'reset@example.com',
    );
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(capturedEmail, 'reset@example.com');
    expect(find.text('Password reset email sent.'), findsOneWidget);
  });

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
                onPressed: () =>
                    context.push('${AppRoutePaths.authOtp}?return_to=previous'),
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
    expect(find.byType(AuthPasswordPage), findsOneWidget);

    await tester.tap(find.text('Use email code instead'));
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
}

class _FakeAuthRepository implements AuthRepository {
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
