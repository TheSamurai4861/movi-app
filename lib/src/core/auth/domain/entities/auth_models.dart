import 'package:flutter/foundation.dart';

import 'package:movi/src/core/auth/domain/entities/auth_failures.dart';

/// Authentication status exposed to the app.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// Minimal session representation (domain-friendly).
///
/// This avoids leaking Supabase SDK models into the Domain layer.
@immutable
class AuthSession {
  const AuthSession({required this.userId});

  final String userId;

  AuthSession copyWith({String? userId}) =>
      AuthSession(userId: userId ?? this.userId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuthSession && other.userId == userId);

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() => 'AuthSession(userId: $userId)';
}

@immutable
class AuthSnapshot {
  const AuthSnapshot({required this.status, this.session});

  final AuthStatus status;
  final AuthSession? session;

  String? get userId => session?.userId;
  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthSnapshot copyWith({AuthStatus? status, AuthSession? session}) {
    return AuthSnapshot(
      status: status ?? this.status,
      session: session ?? this.session,
    );
  }

  static const AuthSnapshot unknown = AuthSnapshot(status: AuthStatus.unknown);
  static const AuthSnapshot unauthenticated = AuthSnapshot(
    status: AuthStatus.unauthenticated,
  );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AuthSnapshot &&
            other.status == status &&
            other.session == session);
  }

  @override
  int get hashCode => Object.hash(status, session);

  @override
  String toString() => 'AuthSnapshot(status: $status, session: $session)';
}

enum AuthBootstrapOutcome { authenticated, reauthRequired, degradedRetryable }

@immutable
class AuthBootstrapResult {
  const AuthBootstrapResult({
    required this.snapshot,
    required this.outcome,
    this.cause,
    this.reasonCode,
    this.recoveryMessage,
  });

  final AuthSnapshot snapshot;
  final AuthBootstrapOutcome outcome;
  final AuthFailureCode? cause;
  final String? reasonCode;
  final String? recoveryMessage;

  bool get isAuthenticated => snapshot.isAuthenticated;
  bool get requiresReauthentication =>
      outcome == AuthBootstrapOutcome.reauthRequired;
  bool get isDegradedRetryable =>
      outcome == AuthBootstrapOutcome.degradedRetryable;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AuthBootstrapResult &&
            other.snapshot == snapshot &&
            other.outcome == outcome &&
            other.cause == cause &&
            other.reasonCode == reasonCode &&
            other.recoveryMessage == recoveryMessage);
  }

  @override
  int get hashCode =>
      Object.hash(snapshot, outcome, cause, reasonCode, recoveryMessage);

  @override
  String toString() {
    return 'AuthBootstrapResult('
        'snapshot: $snapshot, '
        'outcome: $outcome, '
        'cause: $cause, '
        'reasonCode: $reasonCode, '
        'recoveryMessage: $recoveryMessage'
        ')';
  }
}
