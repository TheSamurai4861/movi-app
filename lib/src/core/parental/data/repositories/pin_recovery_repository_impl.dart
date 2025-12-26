import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/core/parental/data/services/profile_pin_edge_service.dart';
import 'package:movi/src/core/parental/domain/entities/pin_recovery_result.dart';
import 'package:movi/src/core/parental/domain/repositories/pin_recovery_repository.dart';

class PinRecoveryRepositoryImpl implements PinRecoveryRepository {
  const PinRecoveryRepositoryImpl({
    required SupabaseClient client,
    required ProfilePinEdgeService profilePin,
  }) : _client = client,
       _profilePin = profilePin;

  final SupabaseClient _client;
  final ProfilePinEdgeService _profilePin;

  @override
  Future<PinRecoveryResult> requestRecoveryCode({String? profileId}) async {
    final email = _client.auth.currentUser?.email?.trim();
    if (email == null || email.isEmpty) {
      return const PinRecoveryResult.failure(PinRecoveryStatus.notAvailable);
    }
    try {
      await _client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );
      return const PinRecoveryResult.success();
    } catch (error) {
      return PinRecoveryResult.failure(_mapError(error));
    }
  }

  @override
  Future<PinRecoveryResult> verifyRecoveryCode(String code) async {
    final email = _client.auth.currentUser?.email?.trim();
    if (email == null || email.isEmpty) {
      return const PinRecoveryResult.failure(PinRecoveryStatus.notAvailable);
    }
    try {
      await _client.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.email,
      );
      return const PinRecoveryResult.success();
    } catch (error) {
      return PinRecoveryResult.failure(_mapError(error));
    }
  }

  @override
  Future<PinRecoveryResult> resetPin({
    required String resetToken,
    required String newPin,
  }) async {
    final profileId = resetToken.trim();
    if (profileId.isEmpty) {
      return const PinRecoveryResult.failure(PinRecoveryStatus.unknown);
    }
    try {
      await _profilePin.setPin(profileId: profileId, pin: newPin);
      return const PinRecoveryResult.success();
    } catch (error) {
      return PinRecoveryResult.failure(_mapError(error));
    }
  }

  PinRecoveryStatus _mapError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('expired')) {
      return PinRecoveryStatus.expired;
    }
    if (message.contains('invalid') || message.contains('token')) {
      return PinRecoveryStatus.invalid;
    }
    if (message.contains('too many') || message.contains('rate')) {
      return PinRecoveryStatus.tooManyAttempts;
    }
    if (message.contains('not found') || message.contains('missing')) {
      return PinRecoveryStatus.notAvailable;
    }
    return PinRecoveryStatus.unknown;
  }
}
