import 'package:movi/src/core/parental/domain/entities/pin_recovery_result.dart';
import 'package:movi/src/core/parental/domain/repositories/pin_recovery_repository.dart';

class RequestPinRecoveryCode {
  const RequestPinRecoveryCode(this._repository);

  final PinRecoveryRepository _repository;

  Future<PinRecoveryResult> call({String? profileId}) {
    return _repository.requestRecoveryCode(profileId: profileId);
  }
}
