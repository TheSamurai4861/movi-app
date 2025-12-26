import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/parental/application/usecases/verify_pin_recovery_code.dart';
import 'package:movi/src/core/parental/domain/entities/pin_recovery_result.dart';
import 'package:movi/src/core/parental/domain/repositories/pin_recovery_repository.dart';

class _FakePinRecoveryRepository implements PinRecoveryRepository {
  _FakePinRecoveryRepository(this.result);

  PinRecoveryResult result;
  String? lastCode;

  @override
  Future<PinRecoveryResult> verifyRecoveryCode(String code) async {
    lastCode = code;
    return result;
  }

  @override
  Future<PinRecoveryResult> requestRecoveryCode({String? profileId}) async {
    return result;
  }

  @override
  Future<PinRecoveryResult> resetPin({
    required String resetToken,
    required String newPin,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  group('VerifyPinRecoveryCode', () {
    test('trims input before calling repository', () async {
      final repo = _FakePinRecoveryRepository(
        const PinRecoveryResult.success(resetToken: 'token'),
      );
      final useCase = VerifyPinRecoveryCode(repo);

      await useCase(' 12345678 ');

      expect(repo.lastCode, '12345678');
    });

    test('returns success result', () async {
      final repo = _FakePinRecoveryRepository(
        const PinRecoveryResult.success(resetToken: 'token'),
      );
      final useCase = VerifyPinRecoveryCode(repo);

      final result = await useCase('12345678');

      expect(result.isSuccess, isTrue);
      expect(result.resetToken, 'token');
    });

    test('returns failure result', () async {
      final repo = _FakePinRecoveryRepository(
        const PinRecoveryResult.failure(PinRecoveryStatus.invalid),
      );
      final useCase = VerifyPinRecoveryCode(repo);

      final result = await useCase('12345678');

      expect(result.isSuccess, isFalse);
      expect(result.status, PinRecoveryStatus.invalid);
    });
  });
}
