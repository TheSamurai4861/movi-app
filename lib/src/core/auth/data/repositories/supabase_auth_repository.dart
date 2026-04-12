import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/core/auth/domain/entities/auth_models.dart';
import 'package:movi/src/core/auth/domain/repositories/auth_repository.dart';

/// Supabase implementation of [AuthRepository].
///
/// Supports:
/// - Email + password authentication
/// - Email OTP (magic link / code) authentication
/// - Sign out
///
/// OAuth/PKCE flows can be added later by implementing additional methods
/// and configuring deep-link redirects in the app.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;
  static const Duration _defaultTimeout = Duration(seconds: 12);

  @override
  Stream<AuthSnapshot> get onAuthStateChange =>
      _client.auth.onAuthStateChange.map((state) {
        final session = state.session;
        final userId = session?.user.id;
        if (userId == null || userId.isEmpty) {
          return AuthSnapshot.unauthenticated;
        }
        return AuthSnapshot(
          status: AuthStatus.authenticated,
          session: AuthSession(userId: userId),
        );
      });

  @override
  AuthSession? get currentSession {
    final session = _client.auth.currentSession;
    final userId = session?.user.id;
    if (userId == null || userId.isEmpty) return null;
    return AuthSession(userId: userId);
  }

  @override
  Future<AuthSession?> refreshSession() async {
    // Supabase refresh can throw when offline or misconfigured.
    final response = await _client.auth.refreshSession().timeout(
      _defaultTimeout,
      onTimeout: () => throw TimeoutException('refreshSession timed out'),
    );

    final userId = response.session?.user.id;
    if (userId == null || userId.isEmpty) return null;
    return AuthSession(userId: userId);
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth
        .signInWithPassword(email: email, password: password)
        .timeout(
          _defaultTimeout,
          onTimeout: () =>
              throw TimeoutException('signInWithPassword timed out'),
        );
  }

  @override
  Future<void> signInWithOtp({
    required String email,
    bool shouldCreateUser = true,
  }) async {
    await _client.auth
        .signInWithOtp(email: email, shouldCreateUser: shouldCreateUser)
        .timeout(
          _defaultTimeout,
          onTimeout: () => throw TimeoutException('signInWithOtp timed out'),
        );
  }

  @override
  Future<bool> verifyOtp({required String email, required String token}) async {
    final response = await _client.auth
        .verifyOTP(email: email, token: token, type: OtpType.email)
        .timeout(
          _defaultTimeout,
          onTimeout: () => throw TimeoutException('verifyOtp timed out'),
        );
    return response.session != null;
  }

  @override
  Future<void> signOut() => _client.auth.signOut().timeout(
    _defaultTimeout,
    onTimeout: () => throw TimeoutException('signOut timed out'),
  );
}
