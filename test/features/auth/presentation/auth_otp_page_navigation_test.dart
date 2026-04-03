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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
    'routes to launch after successful OTP auth in the primary login flow',
    (tester) async {
      final authRepository = _FakeAuthRepository();
      sl.registerSingleton<AuthRepository>(authRepository);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      addTearDown(authRepository.dispose);

      final router = GoRouter(
        initialLocation: AppRoutePaths.authOtp,
        routes: [
          GoRoute(
            path: AppRoutePaths.authOtp,
            builder: (context, state) => const AuthOtpPage(),
          ),
          GoRoute(
            path: AppRoutePaths.launch,
            builder: (context, state) => const Scaffold(body: Text('Launch')),
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

      authRepository.setAuthenticated();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Launch'), findsOneWidget);
      expect(find.byType(AuthOtpPage), findsNothing);
    },
  );
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
