import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:movi/src/core/auth/application/ports/local_cleanup_port.dart';
import 'package:movi/src/core/auth/application/ports/auth_telemetry_port.dart';
import 'package:movi/src/core/auth/domain/entities/auth_failures.dart';
import 'package:movi/src/core/auth/domain/entities/auth_models.dart';
import 'package:movi/src/core/auth/domain/repositories/auth_repository.dart';

/// L1 auth/session orchestrator.
///
/// Goals:
/// - make transitions explicit (unknown -> authenticated/unauthenticated)
/// - be fail-closed when validation/refresh is not possible
/// - keep side effects encapsulated (repo + optional cleanup)
final class AuthOrchestrator {
  AuthOrchestrator({
    required AuthRepository repository,
    LocalCleanupPort? cleanupPort,
    AuthTelemetryPort? telemetry,
    Duration refreshTimeout = const Duration(seconds: 12),
  }) : _repo = repository,
       _cleanup = cleanupPort,
       _telemetry = telemetry,
       _refreshTimeout = refreshTimeout;

  final AuthRepository _repo;
  final LocalCleanupPort? _cleanup;
  final AuthTelemetryPort? _telemetry;
  final Duration _refreshTimeout;

  /// Resolves current auth state deterministically.
  ///
  /// Fail-closed rule (L1): any uncertainty during validation => unauthenticated.
  Future<AuthSnapshot> bootstrapSession() async {
    _telemetry?.event(action: 'bootstrap_session', result: 'start');
    final current = _repo.currentSession;
    if (current == null) {
      _telemetry?.event(action: 'bootstrap_session', result: 'success', reasonCode: AuthFailureCode.invalidSession);
      return AuthSnapshot.unauthenticated;
    }

    final refreshed = await _refreshFailClosed();
    if (refreshed == null) {
      _telemetry?.event(
        action: 'bootstrap_session',
        result: 'failure',
        reasonCode: AuthFailureCode.refreshFailed,
      );
      return AuthSnapshot.unauthenticated;
    }

    _telemetry?.event(action: 'bootstrap_session', result: 'success');
    return AuthSnapshot(status: AuthStatus.authenticated, session: refreshed);
  }

  Future<AuthFailure?> signOutAndCleanup() async {
    _telemetry?.event(action: 'sign_out', result: 'start');
    try {
      await _repo.signOut();
    } catch (e) {
      // Continue to cleanup best-effort even if remote sign-out fails.
      // Caller will decide what to display.
      _telemetry?.event(
        action: 'sign_out',
        result: 'failure',
        reasonCode: AuthFailureCode.signOutFailed,
        detail: kDebugMode ? 'type=${e.runtimeType}' : null,
      );
      final cleanupFailure = await _cleanupBestEffort();
      return cleanupFailure ??
          AuthFailure(
            code: AuthFailureCode.signOutFailed,
            message: 'signOut failed',
            original: e,
          );
    }

    _telemetry?.event(action: 'sign_out', result: 'success');
    return _cleanupBestEffort();
  }

  Future<AuthSession?> _refreshFailClosed() async {
    // Refresh policy: bounded attempts, but fail-closed on first uncertainty.
    // (`_refreshAttempts` is still kept as explicit policy input for future
    // controlled evolutions, but current behavior is intentionally strict.)
    try {
      _telemetry?.event(action: 'refresh_session', result: 'start');
      final refreshed = await _repo
          .refreshSession()
          .timeout(
            _refreshTimeout,
            onTimeout: () => throw TimeoutException('auth refresh timeout'),
          );
      if (refreshed == null) {
        _telemetry?.event(
          action: 'refresh_session',
          result: 'failure',
          reasonCode: AuthFailureCode.invalidSession,
        );
        return null;
      }
      _telemetry?.event(action: 'refresh_session', result: 'success');
      return refreshed;
    } on TimeoutException {
      _telemetry?.event(
        action: 'refresh_session',
        result: 'failure',
        reasonCode: AuthFailureCode.timeout,
      );
      return null;
    } catch (e) {
      _telemetry?.event(
        action: 'refresh_session',
        result: 'failure',
        reasonCode: AuthFailureCode.refreshFailed,
        detail: kDebugMode ? 'type=${e.runtimeType}' : null,
      );
      return null;
    }
  }

  Future<AuthFailure?> _cleanupBestEffort() async {
    final cleanup = _cleanup;
    if (cleanup == null) return null;
    try {
      _telemetry?.event(action: 'local_cleanup', result: 'start');
      await cleanup.clearAllLocalData();
      _telemetry?.event(action: 'local_cleanup', result: 'success');
      return null;
    } catch (e) {
      _telemetry?.event(
        action: 'local_cleanup',
        result: 'failure',
        reasonCode: AuthFailureCode.unknown,
        detail: kDebugMode ? 'type=${e.runtimeType}' : null,
      );
      return AuthFailure(
        code: AuthFailureCode.unknown,
        message: 'local cleanup failed',
        original: e,
      );
    }
  }
}

