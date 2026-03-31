import 'package:movi/src/core/parental/domain/entities/pin_recovery_result.dart';

/// Contrat métier du flux de récupération du PIN.
///
/// Séquence attendue :
/// 1. [requestRecoveryCode] demande l'envoi d'un code de récupération
/// 2. [verifyRecoveryCode] valide ce code et retourne un [resetToken] opaque
/// 3. [resetPin] consomme ce [resetToken] pour définir le nouveau PIN
///
/// Le `resetToken` n'est pas un `profileId` et ne doit pas être transformé en
/// identifiant métier côté application.
abstract class PinRecoveryRepository {
  Future<PinRecoveryResult> requestRecoveryCode({String? profileId});

  Future<PinRecoveryResult> verifyRecoveryCode(String code);

  Future<PinRecoveryResult> resetPin({
    required String resetToken,
    required String newPin,
  });
}
