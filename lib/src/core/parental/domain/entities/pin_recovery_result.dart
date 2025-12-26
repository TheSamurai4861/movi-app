import 'package:flutter/foundation.dart';

enum PinRecoveryStatus {
  success,
  invalid,
  expired,
  tooManyAttempts,
  notAvailable,
  unknown,
}

@immutable
class PinRecoveryResult {
  const PinRecoveryResult._(
    this.status, {
    this.resetToken,
  });

  final PinRecoveryStatus status;
  final String? resetToken;

  bool get isSuccess => status == PinRecoveryStatus.success;

  const PinRecoveryResult.success({String? resetToken})
      : this._(PinRecoveryStatus.success, resetToken: resetToken);

  const PinRecoveryResult.failure(PinRecoveryStatus status)
      : this._(status);
}
