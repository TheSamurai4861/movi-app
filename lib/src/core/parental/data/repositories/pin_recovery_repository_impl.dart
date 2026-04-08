import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/core/parental/data/datasources/pin_recovery_remote_data_source.dart';
import 'package:movi/src/core/parental/domain/entities/pin_recovery_result.dart';
import 'package:movi/src/core/parental/domain/repositories/pin_recovery_repository.dart';

class PinRecoveryRepositoryImpl implements PinRecoveryRepository {
  PinRecoveryRepositoryImpl({
    PinRecoveryRemoteDataSource? remote,
    SupabaseClient? client,
  }) : _remote = _resolveRemote(remote: remote, client: client);

  final PinRecoveryRemoteDataSource _remote;

  static PinRecoveryRemoteDataSource _resolveRemote({
    PinRecoveryRemoteDataSource? remote,
    SupabaseClient? client,
  }) {
    if (remote != null) {
      return remote;
    }
    if (client != null) {
      return PinRecoveryRemoteDataSource(client);
    }

    throw ArgumentError(
      'PinRecoveryRepositoryImpl requires either a PinRecoveryRemoteDataSource '
      'or a SupabaseClient.',
    );
  }

  @override
  Future<PinRecoveryResult> requestRecoveryCode({String? profileId}) async {
    final normalizedProfileId = _normalizeOptional(profileId);

    if (normalizedProfileId == null) {
      return const PinRecoveryResult.failure(PinRecoveryStatus.invalid);
    }

    try {
      final response = await _remote.requestCode(profileId: normalizedProfileId);
      return _mapResponse(response);
    } catch (error) {
      return PinRecoveryResult.failure(_mapError(error));
    }
  }

  @override
  Future<PinRecoveryResult> verifyRecoveryCode(String code) async {
    final normalizedCode = code.trim();
    if (normalizedCode.isEmpty) {
      return const PinRecoveryResult.failure(PinRecoveryStatus.invalid);
    }

    try {
      final response = await _remote.verifyCode(normalizedCode);
      return _mapResponse(response, requireResetTokenOnSuccess: true);
    } catch (error) {
      return PinRecoveryResult.failure(_mapError(error));
    }
  }

  @override
  Future<PinRecoveryResult> resetPin({
    required String resetToken,
    required String newPin,
  }) async {
    final normalizedResetToken = resetToken.trim();
    final normalizedNewPin = newPin.trim();

    if (normalizedResetToken.isEmpty || normalizedNewPin.isEmpty) {
      return const PinRecoveryResult.failure(PinRecoveryStatus.invalid);
    }

    try {
      final response = await _remote.resetPin(
        resetToken: normalizedResetToken,
        newPin: normalizedNewPin,
      );
      return _mapResponse(response);
    } catch (error) {
      return PinRecoveryResult.failure(_mapError(error));
    }
  }

  PinRecoveryResult _mapResponse(
    PinRecoveryResponseDto response, {
    bool requireResetTokenOnSuccess = false,
  }) {
    final status = _mapStatus(status: response.status, message: response.message);

    if (status != PinRecoveryStatus.success) {
      return PinRecoveryResult.failure(status);
    }

    final normalizedResetToken = _normalizeOptional(response.resetToken);
    if (requireResetTokenOnSuccess && normalizedResetToken == null) {
      return const PinRecoveryResult.failure(PinRecoveryStatus.unknown);
    }

    return PinRecoveryResult.success(resetToken: normalizedResetToken);
  }

  PinRecoveryStatus _mapStatus({required String status, String? message}) {
    final normalizedStatus = status.trim().toLowerCase();
    final normalizedMessage = message?.trim().toLowerCase() ?? '';

    switch (normalizedStatus) {
      case 'success':
      case 'ok':
      case 'code_sent':
      case 'sent':
      case 'verified':
      case 'reset':
      case 'reset_success':
        return PinRecoveryStatus.success;
      case 'invalid':
      case 'invalid_code':
      case 'invalid_pin':
      case 'invalid_token':
      case 'missing_code':
      case 'missing_profile':
      case 'missing_token':
      case 'unsupported_action':
        return PinRecoveryStatus.invalid;
      case 'expired':
      case 'expired_code':
      case 'expired_token':
        return PinRecoveryStatus.expired;
      case 'too_many_attempts':
      case 'too_many':
      case 'rate_limited':
      case 'rate_limit':
        return PinRecoveryStatus.tooManyAttempts;
      case 'not_available':
      case 'unavailable':
      case 'not_found':
      case 'missing':
        return PinRecoveryStatus.notAvailable;
    }

    if (normalizedMessage.contains('expired')) {
      return PinRecoveryStatus.expired;
    }
    if (normalizedMessage.contains('invalid') ||
        normalizedMessage.contains('token') ||
        normalizedMessage.contains('code') ||
        normalizedMessage.contains('profile')) {
      return PinRecoveryStatus.invalid;
    }
    if (normalizedMessage.contains('too many') ||
        normalizedMessage.contains('rate')) {
      return PinRecoveryStatus.tooManyAttempts;
    }
    if (normalizedMessage.contains('not found') ||
        normalizedMessage.contains('missing') ||
        normalizedMessage.contains('unavailable')) {
      return PinRecoveryStatus.notAvailable;
    }

    return PinRecoveryStatus.unknown;
  }

  PinRecoveryStatus _mapError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('expired')) {
      return PinRecoveryStatus.expired;
    }
    if (message.contains('invalid') ||
        message.contains('token') ||
        message.contains('code') ||
        message.contains('profile')) {
      return PinRecoveryStatus.invalid;
    }
    if (message.contains('too many') || message.contains('rate')) {
      return PinRecoveryStatus.tooManyAttempts;
    }
    if (message.contains('not found') ||
        message.contains('missing') ||
        message.contains('unavailable')) {
      return PinRecoveryStatus.notAvailable;
    }
    return PinRecoveryStatus.unknown;
  }

  String? _normalizeOptional(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
