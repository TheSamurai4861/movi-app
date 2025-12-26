import 'package:movi/src/core/auth/domain/entities/auth_models.dart';

/// Domain contract for authentication.
///
/// Implementations can be local, Supabase-based, etc.
abstract class AuthRepository {
  /// Emits auth changes (login/logout/token refresh).
  Stream<AuthSnapshot> get onAuthStateChange;

  /// Current session if any.
  AuthSession? get currentSession;

  /// Sign in with email and password.
  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  /// Send a one-time password (OTP) code to the given email.
  ///
  /// If [shouldCreateUser] is true, a new user will be created if one
  /// doesn't exist.
  Future<void> signInWithOtp({
    required String email,
    bool shouldCreateUser = true,
  });

  /// Verify the OTP code received by email.
  ///
  /// Returns true if verification succeeded and the user is now authenticated.
  Future<bool> verifyOtp({
    required String email,
    required String token,
  });

  /// Sign out the current user.
  Future<void> signOut();
}
