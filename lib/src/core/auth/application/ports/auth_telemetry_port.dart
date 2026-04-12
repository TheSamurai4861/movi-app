import 'package:movi/src/core/auth/domain/entities/auth_failures.dart';

/// Telemetry port for auth flows (L1).
///
/// Implementations must never include secrets/PII in payloads.
abstract interface class AuthTelemetryPort {
  void event({
    required String action,
    required String result,
    AuthFailureCode? reasonCode,
    String? detail,
  });
}
