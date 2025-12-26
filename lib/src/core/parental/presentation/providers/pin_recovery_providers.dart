import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'dart:async';

import 'package:movi/src/core/parental/application/usecases/request_pin_recovery_code.dart';
import 'package:movi/src/core/parental/application/usecases/update_profile_pin.dart';
import 'package:movi/src/core/parental/application/usecases/verify_pin_recovery_code.dart';
import 'package:movi/src/core/parental/domain/entities/pin_recovery_result.dart';
import 'package:movi/src/core/parental/domain/repositories/pin_recovery_repository.dart';
import 'package:movi/src/core/parental/presentation/providers/parental_access_providers.dart';
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';
import 'package:movi/src/core/profile/presentation/providers/profiles_providers.dart';

enum PinRecoveryUiStatus {
  idle,
  sendingCode,
  codeSent,
  verifying,
  verified,
  verifyFailed,
  resetting,
  resetSuccess,
  resetFailure,
}

enum PinRecoveryFormError { invalidCode, invalidPin, pinMismatch }

class PinRecoveryUiState {
  static const _unset = Object();

  const PinRecoveryUiState({
    this.status = PinRecoveryUiStatus.idle,
    this.code = '',
    this.cooldownRemaining = 0,
    this.error,
    this.targetProfileId,
    this.resetToken,
    this.newPin = '',
    this.confirmPin = '',
    this.formError,
  });

  final PinRecoveryUiStatus status;
  final String code;
  final int cooldownRemaining;
  final PinRecoveryStatus? error;
  final String? targetProfileId;
  final String? resetToken;
  final String newPin;
  final String confirmPin;
  final PinRecoveryFormError? formError;

  PinRecoveryUiState copyWith({
    PinRecoveryUiStatus? status,
    String? code,
    int? cooldownRemaining,
    Object? error = _unset,
    String? targetProfileId,
    String? resetToken,
    String? newPin,
    String? confirmPin,
    Object? formError = _unset,
  }) {
    return PinRecoveryUiState(
      status: status ?? this.status,
      code: code ?? this.code,
      cooldownRemaining: cooldownRemaining ?? this.cooldownRemaining,
      error: error == _unset ? this.error : error as PinRecoveryStatus?,
      targetProfileId: targetProfileId ?? this.targetProfileId,
      resetToken: resetToken ?? this.resetToken,
      newPin: newPin ?? this.newPin,
      confirmPin: confirmPin ?? this.confirmPin,
      formError: formError == _unset
          ? this.formError
          : formError as PinRecoveryFormError?,
    );
  }
}

final pinRecoveryRepositoryProvider = Provider<PinRecoveryRepository>((ref) {
  return ref.watch(slProvider)<PinRecoveryRepository>();
});

final verifyPinRecoveryCodeProvider = Provider<VerifyPinRecoveryCode>((ref) {
  final repo = ref.watch(pinRecoveryRepositoryProvider);
  return VerifyPinRecoveryCode(repo);
});

final requestPinRecoveryCodeProvider = Provider<RequestPinRecoveryCode>((ref) {
  final repo = ref.watch(pinRecoveryRepositoryProvider);
  return RequestPinRecoveryCode(repo);
});

final updateProfilePinProvider = Provider<UpdateProfilePin>((ref) {
  final repo = ref.watch(pinRecoveryRepositoryProvider);
  return UpdateProfilePin(repo);
});

class PinRecoveryController extends Notifier<PinRecoveryUiState> {
  static const int _codeLength = 8;
  static const int _pinMin = 4;
  static const int _pinMax = 6;
  Timer? _cooldownTimer;

  @override
  PinRecoveryUiState build() {
    ref.onDispose(_disposeTimer);
    return const PinRecoveryUiState();
  }

  void setCode(String raw) {
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final trimmed = digitsOnly.length > _codeLength
        ? digitsOnly.substring(0, _codeLength)
        : digitsOnly;
    final nextStatus =
        state.status == PinRecoveryUiStatus.verifyFailed
            ? PinRecoveryUiStatus.codeSent
            : state.status;

    state = state.copyWith(
      code: trimmed,
      status: nextStatus,
      error: null,
      formError: null,
    );

    if (trimmed.length == _codeLength &&
        nextStatus == PinRecoveryUiStatus.codeSent &&
        state.status != PinRecoveryUiStatus.verifying) {
      verify();
    }
  }

  void setNewPin(String raw) {
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final trimmed = digitsOnly.length > _pinMax
        ? digitsOnly.substring(0, _pinMax)
        : digitsOnly;
    state = state.copyWith(
      newPin: trimmed,
      formError: null,
    );
  }

  void setConfirmPin(String raw) {
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final trimmed = digitsOnly.length > _pinMax
        ? digitsOnly.substring(0, _pinMax)
        : digitsOnly;
    state = state.copyWith(
      confirmPin: trimmed,
      formError: null,
    );
  }

  bool canRequestCode() {
    return state.status != PinRecoveryUiStatus.sendingCode &&
        state.status != PinRecoveryUiStatus.verifying &&
        state.status != PinRecoveryUiStatus.resetting;
  }

  bool canVerify() {
    return state.code.length == _codeLength &&
        state.status != PinRecoveryUiStatus.sendingCode &&
        state.status != PinRecoveryUiStatus.verifying &&
        state.status != PinRecoveryUiStatus.verified &&
        state.status != PinRecoveryUiStatus.resetting &&
        state.status != PinRecoveryUiStatus.resetSuccess &&
        (state.status == PinRecoveryUiStatus.codeSent ||
            state.status == PinRecoveryUiStatus.verifyFailed);
  }

  Future<PinRecoveryResult?> requestCode({String? profileId}) async {
    if (!canRequestCode()) return null;
    final effectiveProfileId =
        (profileId ?? ref.read(currentProfileProvider)?.id)?.trim();

    state = state.copyWith(
      status: PinRecoveryUiStatus.sendingCode,
      error: null,
      formError: null,
      targetProfileId: effectiveProfileId,
    );

    final useCase = ref.read(requestPinRecoveryCodeProvider);
    final result = await useCase(profileId: effectiveProfileId);

    if (result.isSuccess) {
      state = state.copyWith(
        status: PinRecoveryUiStatus.codeSent,
        cooldownRemaining: 60,
        error: null,
        formError: null,
      );
      _startCooldown();
    } else {
      state = state.copyWith(
        status: PinRecoveryUiStatus.idle,
        error: result.status,
      );
    }

    return result;
  }

  Future<PinRecoveryResult?> verify() async {
    if (state.status == PinRecoveryUiStatus.verifying ||
        state.status == PinRecoveryUiStatus.sendingCode) {
      return null;
    }

    if (state.code.length != _codeLength) {
      state = state.copyWith(
        status: PinRecoveryUiStatus.verifyFailed,
        error: PinRecoveryStatus.invalid,
        formError: PinRecoveryFormError.invalidCode,
      );
      return null;
    }

    state = state.copyWith(
      status: PinRecoveryUiStatus.verifying,
      error: null,
      formError: null,
    );
    final useCase = ref.read(verifyPinRecoveryCodeProvider);
    final result = await useCase(state.code);
    final fallbackProfileId = state.targetProfileId ??
        (ref.read(currentProfileProvider)?.id)?.trim();

    if (result.isSuccess) {
      if ((result.resetToken == null || result.resetToken!.trim().isEmpty) &&
          (fallbackProfileId == null || fallbackProfileId.isEmpty)) {
        state = state.copyWith(
          status: PinRecoveryUiStatus.verifyFailed,
          error: PinRecoveryStatus.unknown,
        );
        return result;
      }
      state = state.copyWith(
        status: PinRecoveryUiStatus.verified,
        error: null,
        formError: null,
        resetToken: result.resetToken ?? fallbackProfileId,
      );
    } else {
      state = state.copyWith(
        status: PinRecoveryUiStatus.verifyFailed,
        error: result.status,
      );
    }

    return result;
  }

  Future<void> resendCode({String? profileId}) async {
    if (state.cooldownRemaining > 0) return;
    await requestCode(profileId: profileId);
  }

  bool canReset() {
    return state.status != PinRecoveryUiStatus.resetting &&
        state.resetToken != null &&
        state.newPin.length >= _pinMin &&
        state.newPin.length <= _pinMax &&
        state.newPin == state.confirmPin;
  }

  Future<PinRecoveryResult?> resetPin() async {
    if (state.status == PinRecoveryUiStatus.resetting) return null;
    final token = state.resetToken;
    if (token == null || token.trim().isEmpty) {
      state = state.copyWith(
        status: PinRecoveryUiStatus.resetFailure,
        error: PinRecoveryStatus.unknown,
      );
      return null;
    }

    if (state.newPin.length < _pinMin || state.newPin.length > _pinMax) {
      state = state.copyWith(
        status: PinRecoveryUiStatus.resetFailure,
        formError: PinRecoveryFormError.invalidPin,
      );
      return null;
    }

    if (state.newPin != state.confirmPin) {
      state = state.copyWith(
        status: PinRecoveryUiStatus.resetFailure,
        formError: PinRecoveryFormError.pinMismatch,
      );
      return null;
    }

    state = state.copyWith(
      status: PinRecoveryUiStatus.resetting,
      error: null,
      formError: null,
    );
    final useCase = ref.read(updateProfilePinProvider);
    final result = await useCase(resetToken: token, newPin: state.newPin);

    if (result.isSuccess) {
      state = state.copyWith(
        status: PinRecoveryUiStatus.resetSuccess,
        error: null,
        formError: null,
      );

      ref.invalidate(profilesControllerProvider);
      final profileId = state.resetToken ?? ref.read(currentProfileProvider)?.id;
      if (profileId != null && profileId.trim().isNotEmpty) {
        try {
          final sessionSvc = ref.read(parentalSessionServiceProvider);
          await sessionSvc.lock(profileId);
        } catch (_) {}
      }
    } else {
      state = state.copyWith(
        status: PinRecoveryUiStatus.resetFailure,
        error: result.status,
      );
    }

    return result;
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.cooldownRemaining;
      if (remaining <= 1) {
        timer.cancel();
        state = state.copyWith(cooldownRemaining: 0);
      } else {
        state = state.copyWith(cooldownRemaining: remaining - 1);
      }
    });
  }

  void _disposeTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
  }
}

final pinRecoveryControllerProvider =
    NotifierProvider<PinRecoveryController, PinRecoveryUiState>(
      PinRecoveryController.new,
    );
