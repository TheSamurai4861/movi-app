import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/core/parental/data/datasources/pin_recovery_remote_data_source.dart';
import 'package:movi/src/core/parental/data/services/profile_pin_edge_service.dart';
import 'package:movi/src/core/parental/domain/entities/pin_recovery_result.dart';
import 'package:movi/src/core/parental/domain/repositories/pin_recovery_repository.dart';

class PinRecoveryRepositoryImpl implements PinRecoveryRepository {
  PinRecoveryRepositoryImpl({
    PinRecoveryRemoteDataSource? remote,
    SupabaseClient? client,
    ProfilePinEdgeService? profilePin,
  }) : _remote = _resolveRemote(remote: remote, client: client),
       _profilePin = profilePin,
       _client = client;

  final PinRecoveryRemoteDataSource _remote;
  final ProfilePinEdgeService? _profilePin;
  final SupabaseClient? _client;

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

    try {
      final response = await _remote.requestCode(
        profileId: normalizedProfileId,
      );
      final mapped = _mapResponse(response);
      if (_shouldTryProfilePinFallback(mapped.status)) {
        final profilePinFallback = await _requestRecoveryCodeViaProfilePin(
          normalizedProfileId,
        );
        if (_shouldTryEmailOtpFallback(profilePinFallback.status)) {
          return _requestRecoveryCodeViaEmailOtp();
        }
        return profilePinFallback;
      }
      return mapped;
    } catch (error) {
      final mappedError = _mapError(error);
      if (_shouldTryProfilePinFallback(mappedError)) {
        final profilePinFallback = await _requestRecoveryCodeViaProfilePin(
          normalizedProfileId,
        );
        if (_shouldTryEmailOtpFallback(profilePinFallback.status)) {
          return _requestRecoveryCodeViaEmailOtp();
        }
        return profilePinFallback;
      }
      return PinRecoveryResult.failure(mappedError);
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
      final mapped = _mapResponse(response, requireResetTokenOnSuccess: true);
      if (_shouldTryProfilePinFallback(mapped.status)) {
        final profilePinFallback = await _verifyRecoveryCodeViaProfilePin(
          normalizedCode,
        );
        if (_shouldTryEmailOtpFallback(profilePinFallback.status)) {
          return _verifyRecoveryCodeViaEmailOtp(normalizedCode);
        }
        return profilePinFallback;
      }
      return mapped;
    } catch (error) {
      final mappedError = _mapError(error);
      if (_shouldTryProfilePinFallback(mappedError)) {
        final profilePinFallback = await _verifyRecoveryCodeViaProfilePin(
          normalizedCode,
        );
        if (_shouldTryEmailOtpFallback(profilePinFallback.status)) {
          return _verifyRecoveryCodeViaEmailOtp(normalizedCode);
        }
        return profilePinFallback;
      }
      return PinRecoveryResult.failure(mappedError);
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
      final mapped = _mapResponse(response);
      if (_shouldTryProfilePinFallback(mapped.status)) {
        return _resetPinViaProfilePin(
          resetToken: normalizedResetToken,
          newPin: normalizedNewPin,
        );
      }
      return mapped;
    } catch (error) {
      final mappedError = _mapError(error);
      if (_shouldTryProfilePinFallback(mappedError)) {
        return _resetPinViaProfilePin(
          resetToken: normalizedResetToken,
          newPin: normalizedNewPin,
        );
      }
      return PinRecoveryResult.failure(mappedError);
    }
  }

  Future<PinRecoveryResult> _requestRecoveryCodeViaProfilePin(
    String? profileId,
  ) async {
    final profilePin = _profilePin;
    if (profilePin == null) {
      return const PinRecoveryResult.failure(PinRecoveryStatus.notAvailable);
    }
    try {
      final response = await profilePin.requestRecoveryCode(
        profileId: profileId,
      );
      return _mapProfilePinResponse(response);
    } catch (error) {
      return PinRecoveryResult.failure(_mapError(error));
    }
  }

  Future<PinRecoveryResult> _verifyRecoveryCodeViaProfilePin(
    String code,
  ) async {
    final profilePin = _profilePin;
    if (profilePin == null) {
      return const PinRecoveryResult.failure(PinRecoveryStatus.notAvailable);
    }
    try {
      final response = await profilePin.verifyRecoveryCode(code);
      return _mapProfilePinResponse(response, requireResetTokenOnSuccess: true);
    } catch (error) {
      return PinRecoveryResult.failure(_mapError(error));
    }
  }

  Future<PinRecoveryResult> _resetPinViaProfilePin({
    required String resetToken,
    required String newPin,
  }) async {
    final profilePin = _profilePin;
    if (profilePin == null) {
      return const PinRecoveryResult.failure(PinRecoveryStatus.notAvailable);
    }
    try {
      final response = await profilePin.resetRecoveredPin(
        resetToken: resetToken,
        newPin: newPin,
      );
      final mapped = _mapProfilePinResponse(response);
      if (_shouldTryProfilePinSetFallback(mapped.status)) {
        return _setPinViaProfileId(profileId: resetToken, newPin: newPin);
      }
      return mapped;
    } catch (error) {
      final mappedError = _mapError(error);
      if (_shouldTryProfilePinSetFallback(mappedError)) {
        return _setPinViaProfileId(profileId: resetToken, newPin: newPin);
      }
      return PinRecoveryResult.failure(mappedError);
    }
  }

  Future<PinRecoveryResult> _requestRecoveryCodeViaEmailOtp() async {
    final client = _client;
    final email = client?.auth.currentUser?.email?.trim();
    if (client == null || email == null || email.isEmpty) {
      return const PinRecoveryResult.failure(PinRecoveryStatus.notAvailable);
    }
    try {
      await client.auth.signInWithOtp(email: email, shouldCreateUser: false);
      return const PinRecoveryResult.success();
    } catch (error) {
      return PinRecoveryResult.failure(_mapError(error));
    }
  }

  Future<PinRecoveryResult> _verifyRecoveryCodeViaEmailOtp(String code) async {
    final client = _client;
    final email = client?.auth.currentUser?.email?.trim();
    if (client == null || email == null || email.isEmpty) {
      return const PinRecoveryResult.failure(PinRecoveryStatus.notAvailable);
    }
    try {
      await client.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.email,
      );
      return const PinRecoveryResult.success();
    } catch (error) {
      return PinRecoveryResult.failure(_mapError(error));
    }
  }

  Future<PinRecoveryResult> _setPinViaProfileId({
    required String profileId,
    required String newPin,
  }) async {
    final profilePin = _profilePin;
    if (profilePin == null) {
      return const PinRecoveryResult.failure(PinRecoveryStatus.notAvailable);
    }
    try {
      await profilePin.setPin(profileId: profileId, pin: newPin);
      return const PinRecoveryResult.success();
    } catch (error) {
      return PinRecoveryResult.failure(_mapError(error));
    }
  }

  PinRecoveryResult _mapProfilePinResponse(
    PinRecoveryEdgeResponseDto response, {
    bool requireResetTokenOnSuccess = false,
  }) {
    final status = _mapStatus(
      status: response.status,
      message: response.message,
    );
    if (status != PinRecoveryStatus.success) {
      return PinRecoveryResult.failure(status);
    }

    final normalizedResetToken = _normalizeOptional(response.resetToken);
    if (requireResetTokenOnSuccess && normalizedResetToken == null) {
      return const PinRecoveryResult.failure(PinRecoveryStatus.unknown);
    }

    return PinRecoveryResult.success(resetToken: normalizedResetToken);
  }

  bool _shouldTryProfilePinFallback(PinRecoveryStatus status) {
    return status == PinRecoveryStatus.notAvailable ||
        status == PinRecoveryStatus.unknown;
  }

  bool _shouldTryEmailOtpFallback(PinRecoveryStatus status) {
    return status == PinRecoveryStatus.notAvailable ||
        status == PinRecoveryStatus.unknown;
  }

  bool _shouldTryProfilePinSetFallback(PinRecoveryStatus status) {
    return status == PinRecoveryStatus.notAvailable ||
        status == PinRecoveryStatus.unknown;
  }

  PinRecoveryResult _mapResponse(
    PinRecoveryResponseDto response, {
    bool requireResetTokenOnSuccess = false,
  }) {
    final status = _mapStatus(
      status: response.status,
      message: response.message,
    );

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
      case 'invalid_token':
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
        normalizedMessage.contains('token')) {
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
    if (message.contains('invalid') || message.contains('token')) {
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
