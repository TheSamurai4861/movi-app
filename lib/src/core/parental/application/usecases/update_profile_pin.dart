import 'package:movi/src/core/parental/domain/entities/pin_recovery_result.dart';
import 'package:movi/src/core/parental/domain/repositories/pin_recovery_repository.dart';

class UpdateProfilePin {
  const UpdateProfilePin(this._repository);

  final PinRecoveryRepository _repository;

  Future<PinRecoveryResult> call({
    required String resetToken,
    required String newPin,
  }) {
    return _repository.resetPin(resetToken: resetToken, newPin: newPin);
  }
}
