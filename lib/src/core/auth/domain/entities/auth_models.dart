import 'package:flutter/foundation.dart';

/// Authentication status exposed to the app.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// Minimal session representation (domain-friendly).
///
/// This avoids leaking Supabase SDK models into the Domain layer.
@immutable
class AuthSession {
  const AuthSession({required this.userId});

  final String userId;

  AuthSession copyWith({String? userId}) => AuthSession(userId: userId ?? this.userId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AuthSession && other.userId == userId);

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() => 'AuthSession(userId: $userId)';
}

@immutable
class AuthSnapshot {
  const AuthSnapshot({
    required this.status,
    this.session,
  });

  final AuthStatus status;
  final AuthSession? session;

  String? get userId => session?.userId;
  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthSnapshot copyWith({
    AuthStatus? status,
    AuthSession? session,
  }) {
    return AuthSnapshot(
      status: status ?? this.status,
      session: session ?? this.session,
    );
  }

  static const AuthSnapshot unknown = AuthSnapshot(status: AuthStatus.unknown);
  static const AuthSnapshot unauthenticated =
      AuthSnapshot(status: AuthStatus.unauthenticated);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AuthSnapshot && other.status == status && other.session == session);
  }

  @override
  int get hashCode => Object.hash(status, session);

  @override
  String toString() => 'AuthSnapshot(status: $status, session: $session)';
}
