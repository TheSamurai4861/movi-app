import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/core/supabase/supabase_providers.dart';
import 'package:movi/src/core/supabase/supabase_error_mapper.dart';

@immutable
class AuthOtpState {
  const AuthOtpState({
    this.status = AuthOtpStatus.idle,
    this.email = '',
    this.code = '',
    this.cooldownRemaining = 0,
    this.emailError,
    this.codeError,
    this.globalErrorKey,
    this.globalError,
  });

  final AuthOtpStatus status;
  final String email;
  final String code;
  final int cooldownRemaining;

  final AuthOtpEmailError? emailError;
  final String? codeError;
  final AuthOtpGlobalError? globalErrorKey;
  final String? globalError;

  AuthOtpState copyWith({
    AuthOtpStatus? status,
    String? email,
    String? code,
    int? cooldownRemaining,
    AuthOtpEmailError? emailError,
    String? codeError,
    AuthOtpGlobalError? globalErrorKey,
    String? globalError,
  }) {
    return AuthOtpState(
      status: status ?? this.status,
      email: email ?? this.email,
      code: code ?? this.code,
      cooldownRemaining: cooldownRemaining ?? this.cooldownRemaining,
      emailError: emailError,
      codeError: codeError,
      globalErrorKey: globalErrorKey,
      globalError: globalError,
    );
  }
}

enum AuthOtpEmailError { invalid }

enum AuthOtpGlobalError { supabaseUnavailable }

enum AuthOtpStatus {
  idle,
  sendingCode,
  codeSent,
  verifyingCode,
}

class AuthOtpController extends Notifier<AuthOtpState> {
  Timer? _cooldownTimer;

  @override
  AuthOtpState build() {
    ref.onDispose(_disposeTimer);
    return const AuthOtpState();
  }

  void setEmail(String raw) {
    final normalized = raw.trim().toLowerCase();
    state = state.copyWith(
      email: normalized,
      emailError: null,
      globalError: null,
      globalErrorKey: null,
    );
  }

  static const int _codeLength = 8;

  void setCode(String raw) {
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final trimmed = digitsOnly.length > _codeLength
        ? digitsOnly.substring(0, _codeLength)
        : digitsOnly;
    state = state.copyWith(
      code: trimmed,
      codeError: null,
      globalError: null,
      globalErrorKey: null,
    );

    if (trimmed.length == _codeLength &&
        state.status != AuthOtpStatus.verifyingCode &&
        state.status != AuthOtpStatus.sendingCode) {
      // Auto-submit when we have all digits.
      verifyCode();
    }
  }

  bool _validateEmail() {
    final email = state.email;
    if (email.isEmpty ||
        !email.contains('@') ||
        !email.contains('.')) {
      state = state.copyWith(
        emailError: AuthOtpEmailError.invalid,
      );
      return false;
    }
    return true;
  }

  SupabaseClient? _clientOrNull() {
    final client = ref.read(supabaseClientProvider);
    return client;
  }

  Future<bool> sendCode() async {
    if (state.status == AuthOtpStatus.sendingCode ||
        state.status == AuthOtpStatus.verifyingCode) {
      return false;
    }

    if (!_validateEmail()) {
      return false;
    }

    final client = _clientOrNull();
    if (client == null) {
      state = state.copyWith(
        globalErrorKey: AuthOtpGlobalError.supabaseUnavailable,
        globalError: null,
      );
      return false;
    }

    state = state.copyWith(
      status: AuthOtpStatus.sendingCode,
      globalError: null,
      codeError: null,
      globalErrorKey: null,
    );

    try {
      await client.auth.signInWithOtp(
        email: state.email,
        shouldCreateUser: true,
      );

      state = state.copyWith(
        status: AuthOtpStatus.codeSent,
        cooldownRemaining: 60,
      );
      _startCooldown();
      return true;
    } catch (error, stackTrace) {
      final failure = mapSupabaseError(error, stackTrace: stackTrace);
      state = state.copyWith(
        status: AuthOtpStatus.idle,
        globalError: failure.message,
        globalErrorKey: null,
      );
      return false;
    }
  }

  Future<void> verifyCode() async {
    if (state.status == AuthOtpStatus.verifyingCode ||
        state.code.length != _codeLength) {
      return;
    }

    final client = _clientOrNull();
    if (client == null) {
      state = state.copyWith(
        globalErrorKey: AuthOtpGlobalError.supabaseUnavailable,
        globalError: null,
      );
      return;
    }

    if (!_validateEmail()) {
      return;
    }

    state = state.copyWith(
      status: AuthOtpStatus.verifyingCode,
      globalError: null,
      codeError: null,
      globalErrorKey: null,
    );

    try {
      await client.auth.verifyOTP(
        email: state.email,
        token: state.code,
        type: OtpType.email,
      );

      // L'état d'auth globale sera mis à jour via AuthController.
      state = state.copyWith(
        status: AuthOtpStatus.idle,
      );
    } catch (error, stackTrace) {
      final failure = mapSupabaseError(error, stackTrace: stackTrace);
      state = state.copyWith(
        status: AuthOtpStatus.codeSent,
        codeError: failure.message,
      );
    }
  }

  Future<void> resendCode() async {
    if (state.cooldownRemaining > 0) return;
    await sendCode();
  }

  void resetToEmailStep() {
    state = state.copyWith(
      status: AuthOtpStatus.idle,
      code: '',
      cooldownRemaining: 0,
      codeError: null,
      globalError: null,
      globalErrorKey: null,
    );
    _disposeTimer();
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

final authOtpControllerProvider =
    NotifierProvider<AuthOtpController, AuthOtpState>(AuthOtpController.new);


