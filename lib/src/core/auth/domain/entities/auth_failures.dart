import 'package:flutter/foundation.dart';

/// Failure codes for authentication/session flows (L1).
enum AuthFailureCode {
  unknown,
  notConfigured,
  timeout,
  offline,
  invalidSession,
  refreshFailed,
  signInFailed,
  verifyOtpFailed,
  signOutFailed,
}

@immutable
class AuthFailure {
  const AuthFailure({required this.code, required this.message, this.original});

  final AuthFailureCode code;
  final String message;
  final Object? original;

  @override
  String toString() => 'AuthFailure(code: $code, message: $message)';
}
