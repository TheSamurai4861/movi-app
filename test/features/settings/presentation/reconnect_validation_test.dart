import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/auth/domain/entities/auth_models.dart';
import 'package:movi/src/core/auth/domain/repositories/auth_repository.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/features/auth/presentation/auth_password_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
    'returns to previous screen after successful password auth launched from settings',
    (tester) async {
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
                  onPressed: () => context.push('/auth'),
                  child: const Text('Open auth'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/auth',
            builder: (context, state) =>
                const AuthPasswordPage(returnOnSuccess: true),
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

      expect(find.text('Open auth'), findsOneWidget);

      await tester.tap(find.text('Open auth'));
      await tester.pumpAndSettle();

      expect(find.byType(AuthPasswordPage), findsOneWidget);

      authRepository.setAuthenticated();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Open auth'), findsOneWidget);
      expect(find.byType(AuthPasswordPage), findsNothing);
    },
  );
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({AuthSession? initialSession})
    : _session = initialSession;

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

  void setUnauthenticated() {
    _session = null;
    _controller.add(AuthSnapshot.unauthenticated);
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
    setUnauthenticated();
  }

  void dispose() {
    _controller.close();
  }
}
