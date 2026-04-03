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
  _AuthRepoFake({
    this.session,
    this.refreshDelay,
    this.refreshThrows,
    this.returnNullOnRefresh = false,
  });

  AuthSession? session;
  Duration? refreshDelay;
  Object? refreshThrows;
  bool returnNullOnRefresh;
  int signOutCalls = 0;

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
    if (returnNullOnRefresh) return null;
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
  Future<bool> verifyOtp({
    required String email,
    required String token,
  }) async => false;

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
    session = null;
  }
}

final class _CleanupFake implements LocalCleanupPort {
  _CleanupFake({this.throwOnCleanup});
  int fullCleanupCalls = 0;
  int sensitiveCleanupCalls = 0;
  final Object? throwOnCleanup;

  @override
  Future<void> clearSensitiveSessionState() async {
    sensitiveCleanupCalls += 1;
    final t = throwOnCleanup;
    if (t != null) throw t;
  }

  @override
  Future<void> clearAllLocalData() async {
    fullCleanupCalls += 1;
    final t = throwOnCleanup;
    if (t != null) throw t;
  }
}

void main() {
  test(
    'bootstrapSession returns unauthenticated when no current session',
    () async {
      final repo = _AuthRepoFake(session: null);
      final telemetry = _TelemetryFake();
      final orch = AuthOrchestrator(repository: repo, telemetry: telemetry);

      final result = await orch.bootstrapSession();
      expect(result.snapshot.status, AuthStatus.unauthenticated);
      expect(result.outcome, AuthBootstrapOutcome.reauthRequired);
      expect(result.cause, AuthFailureCode.invalidSession);
      expect(telemetry.events.join('\n'), contains('action=bootstrap_session'));
    },
  );

  test(
    'bootstrapSession returns authenticated when refresh succeeds',
    () async {
      final repo = _AuthRepoFake(session: const AuthSession(userId: 'u1'));
      final telemetry = _TelemetryFake();
      final orch = AuthOrchestrator(repository: repo, telemetry: telemetry);

      final result = await orch.bootstrapSession();
      expect(result.snapshot.status, AuthStatus.authenticated);
      expect(result.snapshot.userId, 'u1');
      expect(result.outcome, AuthBootstrapOutcome.authenticated);
      expect(
        telemetry.events.join('\n'),
        contains('action=refresh_session result=success'),
      );
    },
  );

  test(
    'bootstrapSession degrades retryably when refresh fails offline',
    () async {
      final repo = _AuthRepoFake(
        session: const AuthSession(userId: 'u1'),
        refreshThrows: StateError('offline'),
      );
      final telemetry = _TelemetryFake();
      final orch = AuthOrchestrator(repository: repo, telemetry: telemetry);

      final result = await orch.bootstrapSession();
      expect(result.snapshot.status, AuthStatus.unauthenticated);
      expect(result.outcome, AuthBootstrapOutcome.degradedRetryable);
      expect(result.cause, AuthFailureCode.offline);
      expect(
        telemetry.events.join('\n'),
        contains('reasonCode=${AuthFailureCode.offline.name}'),
      );
    },
  );

  test('bootstrapSession degrades retryably when refresh times out', () async {
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

    final result = await orch.bootstrapSession();
    expect(result.snapshot.status, AuthStatus.unauthenticated);
    expect(result.outcome, AuthBootstrapOutcome.degradedRetryable);
    expect(result.cause, AuthFailureCode.timeout);
    expect(
      telemetry.events.join('\n'),
      contains('reasonCode=${AuthFailureCode.timeout.name}'),
    );
  });

  test(
    'bootstrapSession clears sensitive session state on invalid session',
    () async {
      final repo = _AuthRepoFake(
        session: const AuthSession(userId: 'u1'),
        returnNullOnRefresh: true,
      );
      final telemetry = _TelemetryFake();
      final cleanup = _CleanupFake();
      final orch = AuthOrchestrator(
        repository: repo,
        cleanupPort: cleanup,
        telemetry: telemetry,
      );

      final result = await orch.bootstrapSession();

      expect(result.snapshot.status, AuthStatus.unauthenticated);
      expect(result.outcome, AuthBootstrapOutcome.reauthRequired);
      expect(result.cause, AuthFailureCode.invalidSession);
      expect(repo.signOutCalls, 1);
      expect(cleanup.sensitiveCleanupCalls, 1);
      expect(cleanup.fullCleanupCalls, 0);
      expect(
        telemetry.events.join('\n'),
        contains('action=sensitive_cleanup result=success'),
      );
    },
  );

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
    expect(cleanup.fullCleanupCalls, 1);
    expect(
      telemetry.events.join('\n'),
      contains('action=local_cleanup result=success'),
    );
  });

  test(
    'signOutAndCleanup returns cleanup failure when cleanup fails',
    () async {
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
      expect(
        telemetry.events.join('\n'),
        contains('action=local_cleanup result=failure'),
      );
    },
  );

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
