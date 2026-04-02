import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/auth/application/auth_orchestrator.dart';
import 'package:movi/src/core/auth/application/ports/auth_telemetry_port.dart';
import 'package:movi/src/core/auth/application/ports/local_cleanup_port.dart';
import 'package:movi/src/core/auth/domain/entities/auth_failures.dart';
import 'package:movi/src/core/auth/domain/entities/auth_models.dart';
import 'package:movi/src/core/auth/domain/repositories/auth_repository.dart';

final class _TelemetryFake implements AuthTelemetryPort {
  final List<String> events = <String>[];

  @override
  void event({
    required String action,
    required String result,
    AuthFailureCode? reasonCode,
    String? detail,
  }) {
    final reason = reasonCode?.name ?? '';
    final det = detail ?? '';
    events.add('action=$action result=$result reasonCode=$reason detail=$det');
  }
}

final class _AuthRepoFake implements AuthRepository {
  _AuthRepoFake({this.session, this.refreshDelay, this.refreshThrows});

  AuthSession? session;
  Duration? refreshDelay;
  Object? refreshThrows;

  @override
  Stream<AuthSnapshot> get onAuthStateChange =>
      const Stream<AuthSnapshot>.empty();

  @override
  AuthSession? get currentSession => session;

  @override
  Future<AuthSession?> refreshSession() async {
    final d = refreshDelay;
    if (d != null) await Future<void>.delayed(d);
    final t = refreshThrows;
    if (t != null) throw t;
    return session;
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInWithOtp({required String email, bool shouldCreateUser = true}) async {}

  @override
  Future<bool> verifyOtp({required String email, required String token}) async =>
      false;

  @override
  Future<void> signOut() async {}
}

final class _CleanupFake implements LocalCleanupPort {
  _CleanupFake({this.throwOnCleanup});
  int calls = 0;
  final Object? throwOnCleanup;

  @override
  Future<void> clearAllLocalData() async {
    calls += 1;
    final t = throwOnCleanup;
    if (t != null) throw t;
  }
}

void main() {
  test('bootstrapSession returns unauthenticated when no current session', () async {
    final repo = _AuthRepoFake(session: null);
    final telemetry = _TelemetryFake();
    final orch = AuthOrchestrator(repository: repo, telemetry: telemetry);

    final snap = await orch.bootstrapSession();
    expect(snap.status, AuthStatus.unauthenticated);
    expect(
      telemetry.events.join('\n'),
      contains('action=bootstrap_session'),
    );
  });

  test('bootstrapSession returns authenticated when refresh succeeds', () async {
    final repo = _AuthRepoFake(session: const AuthSession(userId: 'u1'));
    final telemetry = _TelemetryFake();
    final orch = AuthOrchestrator(repository: repo, telemetry: telemetry);

    final snap = await orch.bootstrapSession();
    expect(snap.status, AuthStatus.authenticated);
    expect(snap.userId, 'u1');
    expect(telemetry.events.join('\n'), contains('action=refresh_session result=success'));
  });

  test('bootstrapSession is fail-closed when refresh throws', () async {
    final repo = _AuthRepoFake(
      session: const AuthSession(userId: 'u1'),
      refreshThrows: StateError('offline'),
    );
    final telemetry = _TelemetryFake();
    final orch = AuthOrchestrator(repository: repo, telemetry: telemetry);

    final snap = await orch.bootstrapSession();
    expect(snap.status, AuthStatus.unauthenticated);
    expect(
      telemetry.events.join('\n'),
      contains('reasonCode=${AuthFailureCode.refreshFailed.name}'),
    );
  });

  test('bootstrapSession is fail-closed when refresh times out', () async {
    final repo = _AuthRepoFake(
      session: const AuthSession(userId: 'u1'),
      refreshDelay: const Duration(milliseconds: 50),
    );
    final telemetry = _TelemetryFake();
    final orch = AuthOrchestrator(
      repository: repo,
      telemetry: telemetry,
      refreshTimeout: const Duration(milliseconds: 1),
    );

    final snap = await orch.bootstrapSession();
    expect(snap.status, AuthStatus.unauthenticated);
    expect(
      telemetry.events.join('\n'),
      contains('reasonCode=${AuthFailureCode.timeout.name}'),
    );
  });

  test('signOutAndCleanup runs cleanup best-effort', () async {
    final repo = _AuthRepoFake(session: const AuthSession(userId: 'u1'));
    final telemetry = _TelemetryFake();
    final cleanup = _CleanupFake();
    final orch = AuthOrchestrator(
      repository: repo,
      cleanupPort: cleanup,
      telemetry: telemetry,
    );

    final failure = await orch.signOutAndCleanup();
    expect(failure, isNull);
    expect(cleanup.calls, 1);
    expect(telemetry.events.join('\n'), contains('action=local_cleanup result=success'));
  });

  test('signOutAndCleanup returns cleanup failure when cleanup fails', () async {
    final repo = _AuthRepoFake(session: const AuthSession(userId: 'u1'));
    final telemetry = _TelemetryFake();
    final cleanup = _CleanupFake(throwOnCleanup: StateError('disk error'));
    final orch = AuthOrchestrator(
      repository: repo,
      cleanupPort: cleanup,
      telemetry: telemetry,
    );

    final failure = await orch.signOutAndCleanup();
    expect(failure, isNotNull);
    expect(failure!.code, AuthFailureCode.unknown);
    expect(telemetry.events.join('\n'), contains('action=local_cleanup result=failure'));
  });

  test('auth telemetry does not leak secrets/PII (basic patterns)', () async {
    final repo = _AuthRepoFake(session: const AuthSession(userId: 'u1'));
    final telemetry = _TelemetryFake();
    final orch = AuthOrchestrator(repository: repo, telemetry: telemetry);

    await orch.bootstrapSession();
    await orch.signOutAndCleanup();

    final blob = telemetry.events.join('\n').toLowerCase();
    const forbidden = <String>[
      'password',
      'otp',
      'token=',
      'access_token',
      'refresh_token',
      '@', // email indicator
    ];

    for (final f in forbidden) {
      expect(blob.contains(f), isFalse, reason: 'Leaked forbidden pattern: $f');
    }
  });
}

