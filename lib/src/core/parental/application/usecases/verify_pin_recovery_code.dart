import 'package:movi/src/core/parental/domain/entities/pin_recovery_result.dart';
import 'package:movi/src/core/parental/domain/repositories/pin_recovery_repository.dart';

class VerifyPinRecoveryCode {
  const VerifyPinRecoveryCode(this._repository);

  final PinRecoveryRepository _repository;

  Future<PinRecoveryResult> call(String code) {
    final trimmed = code.trim();
    return _repository.verifyRecoveryCode(trimmed);
  }
}
