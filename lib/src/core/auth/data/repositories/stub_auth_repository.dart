import 'package:movi/src/core/auth/domain/entities/auth_models.dart';
import 'package:movi/src/core/auth/domain/repositories/auth_repository.dart';

/// Fallback implementation used when Supabase is not configured.
///
/// Emits [AuthSnapshot.unauthenticated] for each listener.
class StubAuthRepository implements AuthRepository {
  StubAuthRepository();

  final Stream<AuthSnapshot> _stream = Stream<AuthSnapshot>.multi(
    (controller) {
      controller.add(AuthSnapshot.unauthenticated);
      controller.close();
    },
    isBroadcast: true,
  );

  @override
  Stream<AuthSnapshot> get onAuthStateChange => _stream;

  @override
  AuthSession? get currentSession => null;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    throw StateError(
      'Auth is not configured. '
      'Configure Supabase to enable sign-in.',
    );
  }

  @override
  Future<void> signInWithOtp({
    required String email,
    bool shouldCreateUser = true,
  }) async {
    throw StateError(
      'Auth is not configured. '
      'Configure Supabase to enable OTP sign-in.',
    );
  }

  @override
  Future<bool> verifyOtp({
    required String email,
    required String token,
  }) async {
    throw StateError(
      'Auth is not configured. '
      'Configure Supabase to enable OTP verification.',
    );
  }

  @override
  Future<void> signOut() async {
    // No-op.
  }
}
