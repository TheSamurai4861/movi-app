import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:movi/src/core/auth/application/ports/auth_telemetry_port.dart';
import 'package:movi/src/core/auth/application/ports/local_cleanup_port.dart';
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
  /// Fail-closed rule (L1): a validated session is required before exposing an
  /// authenticated path. Invalid sessions force reauthentication; transient
  /// failures keep the app unauthenticated but explicitly retryable.
  Future<AuthBootstrapResult> bootstrapSession() async {
    _telemetry?.event(action: 'bootstrap_session', result: 'start');

    final current = _repo.currentSession;
    if (current == null) {
      _telemetry?.event(
        action: 'bootstrap_session',
        result: 'success',
        reasonCode: AuthFailureCode.invalidSession,
      );
      return _reauthRequiredResult(AuthFailureCode.invalidSession);
    }

    final refreshed = await _refreshFailClosed();
    if (refreshed.session != null) {
      _telemetry?.event(action: 'bootstrap_session', result: 'success');
      return AuthBootstrapResult(
        snapshot: AuthSnapshot(
          status: AuthStatus.authenticated,
          session: refreshed.session,
        ),
        outcome: AuthBootstrapOutcome.authenticated,
        reasonCode: 'authenticated',
      );
    }

    final cause = refreshed.cause ?? AuthFailureCode.refreshFailed;
    if (cause == AuthFailureCode.invalidSession) {
      await _clearInvalidSessionStateBestEffort();
      _telemetry?.event(
        action: 'bootstrap_session',
        result: 'failure',
        reasonCode: cause,
      );
      return _reauthRequiredResult(cause);
    }

    _telemetry?.event(
      action: 'bootstrap_session',
      result: 'failure',
      reasonCode: cause,
    );
    return AuthBootstrapResult(
      snapshot: AuthSnapshot.unauthenticated,
      outcome: AuthBootstrapOutcome.degradedRetryable,
      cause: cause,
      reasonCode: cause.name,
      recoveryMessage: _degradedMessageFor(cause),
    );
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

  Future<_RefreshSessionResult> _refreshFailClosed() async {
    try {
      _telemetry?.event(action: 'refresh_session', result: 'start');
      final refreshed = await _repo.refreshSession().timeout(
        _refreshTimeout,
        onTimeout: () => throw TimeoutException('auth refresh timeout'),
      );
      if (refreshed == null) {
        _telemetry?.event(
          action: 'refresh_session',
          result: 'failure',
          reasonCode: AuthFailureCode.invalidSession,
        );
        return const _RefreshSessionResult(
          cause: AuthFailureCode.invalidSession,
        );
      }
      _telemetry?.event(action: 'refresh_session', result: 'success');
      return _RefreshSessionResult(session: refreshed);
    } on TimeoutException {
      _telemetry?.event(
        action: 'refresh_session',
        result: 'failure',
        reasonCode: AuthFailureCode.timeout,
      );
      return const _RefreshSessionResult(cause: AuthFailureCode.timeout);
    } catch (e) {
      final cause = _classifyRefreshFailure(e);
      _telemetry?.event(
        action: 'refresh_session',
        result: 'failure',
        reasonCode: cause,
        detail: kDebugMode ? 'type=${e.runtimeType}' : null,
      );
      return _RefreshSessionResult(cause: cause);
    }
  }

  AuthBootstrapResult _reauthRequiredResult(AuthFailureCode cause) {
    return AuthBootstrapResult(
      snapshot: AuthSnapshot.unauthenticated,
      outcome: AuthBootstrapOutcome.reauthRequired,
      cause: cause,
      reasonCode: cause.name,
      recoveryMessage: _reauthMessageFor(cause),
    );
  }

  AuthFailureCode _classifyRefreshFailure(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('offline') ||
        message.contains('failed host lookup') ||
        message.contains('socketexception') ||
        message.contains('host is down') ||
        message.contains('network is unreachable') ||
        message.contains('connection refused')) {
      return AuthFailureCode.offline;
    }
    if (message.contains('timeout') || message.contains('timed out')) {
      return AuthFailureCode.timeout;
    }
    return AuthFailureCode.refreshFailed;
  }

  String _reauthMessageFor(AuthFailureCode cause) {
    return switch (cause) {
      AuthFailureCode.invalidSession =>
        'Session expiree. Reconnectez-vous pour retablir l\'acces.',
      _ => 'Reconnectez-vous pour retablir l\'acces.',
    };
  }

  String _degradedMessageFor(AuthFailureCode cause) {
    return switch (cause) {
      AuthFailureCode.offline =>
        'Connexion indisponible. Vous pouvez continuer en mode degrade et reessayer.',
      AuthFailureCode.timeout =>
        'La restauration de session a expire. Vous pouvez continuer en mode degrade et reessayer.',
      AuthFailureCode.refreshFailed =>
        'Le service de session est temporairement indisponible. Vous pouvez continuer en mode degrade et reessayer.',
      _ =>
        'La session ne peut pas etre restauree maintenant. Vous pouvez continuer en mode degrade et reessayer.',
    };
  }

  Future<void> _clearInvalidSessionStateBestEffort() async {
    _telemetry?.event(
      action: 'invalidate_session',
      result: 'start',
      reasonCode: AuthFailureCode.invalidSession,
    );

    try {
      await _repo.signOut();
      _telemetry?.event(
        action: 'invalidate_session',
        result: 'success',
        reasonCode: AuthFailureCode.invalidSession,
      );
    } catch (e) {
      _telemetry?.event(
        action: 'invalidate_session',
        result: 'failure',
        reasonCode: AuthFailureCode.invalidSession,
        detail: kDebugMode ? 'type=${e.runtimeType}' : null,
      );
    }

    final cleanup = _cleanup;
    if (cleanup == null) return;

    try {
      _telemetry?.event(
        action: 'sensitive_cleanup',
        result: 'start',
        reasonCode: AuthFailureCode.invalidSession,
      );
      await cleanup.clearSensitiveSessionState();
      _telemetry?.event(
        action: 'sensitive_cleanup',
        result: 'success',
        reasonCode: AuthFailureCode.invalidSession,
      );
    } catch (e) {
      _telemetry?.event(
        action: 'sensitive_cleanup',
        result: 'failure',
        reasonCode: AuthFailureCode.invalidSession,
        detail: kDebugMode ? 'type=${e.runtimeType}' : null,
      );
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

@immutable
final class _RefreshSessionResult {
  const _RefreshSessionResult({this.session, this.cause});

  final AuthSession? session;
  final AuthFailureCode? cause;
}
