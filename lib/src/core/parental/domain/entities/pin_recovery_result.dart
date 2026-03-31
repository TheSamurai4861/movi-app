import 'package:flutter/foundation.dart';

enum PinRecoveryStatus {
  success,
  invalid,
  expired,
  tooManyAttempts,
  notAvailable,
  unknown,
}

/// Résultat du flux de récupération du PIN.
///
/// [resetToken] est un jeton opaque émis par le backend de récupération après
/// une vérification réussie du code. Il doit être retransmis tel quel à l'étape
/// de reset et ne doit jamais être interprété comme un identifiant métier.
@immutable
class PinRecoveryResult {
  const PinRecoveryResult._(this.status, {this.resetToken});

  final PinRecoveryStatus status;
  final String? resetToken;

  bool get isSuccess => status == PinRecoveryStatus.success;

  const PinRecoveryResult.success({String? resetToken})
    : this._(PinRecoveryStatus.success, resetToken: resetToken);

  const PinRecoveryResult.failure(PinRecoveryStatus status) : this._(status);
}
