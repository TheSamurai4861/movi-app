import 'package:movi/src/core/parental/domain/entities/pin_recovery_result.dart';

abstract class PinRecoveryRepository {
  Future<PinRecoveryResult> requestRecoveryCode({String? profileId});

  Future<PinRecoveryResult> verifyRecoveryCode(String code);

  Future<PinRecoveryResult> resetPin({
    required String resetToken,
    required String newPin,
  });
}
