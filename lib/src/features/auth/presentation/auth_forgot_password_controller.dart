import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/config/env/environment.dart';
import 'package:movi/src/core/config/env/environment_loader.dart';
import 'package:movi/src/core/router/app_route_paths.dart';
import 'package:movi/src/core/supabase/supabase_error_mapper.dart';
import 'package:movi/src/core/supabase/supabase_providers.dart';

@immutable
class AuthForgotPasswordState {
  const AuthForgotPasswordState({
    this.status = AuthForgotPasswordStatus.idle,
    this.email = '',
    this.emailError,
    this.globalErrorKey,
    this.globalError,
    this.noticeKey,
  });

  final AuthForgotPasswordStatus status;
  final String email;
  final AuthForgotPasswordEmailError? emailError;
  final AuthForgotPasswordGlobalError? globalErrorKey;
  final String? globalError;
  final AuthForgotPasswordNotice? noticeKey;

  static const Object _unset = Object();

  AuthForgotPasswordState copyWith({
    AuthForgotPasswordStatus? status,
    String? email,
    Object? emailError = _unset,
    Object? globalErrorKey = _unset,
    Object? globalError = _unset,
    Object? noticeKey = _unset,
  }) {
    return AuthForgotPasswordState(
      status: status ?? this.status,
      email: email ?? this.email,
      emailError: identical(emailError, _unset)
          ? this.emailError
          : emailError as AuthForgotPasswordEmailError?,
      globalErrorKey: identical(globalErrorKey, _unset)
          ? this.globalErrorKey
          : globalErrorKey as AuthForgotPasswordGlobalError?,
      globalError: identical(globalError, _unset)
          ? this.globalError
          : globalError as String?,
      noticeKey: identical(noticeKey, _unset)
          ? this.noticeKey
          : noticeKey as AuthForgotPasswordNotice?,
    );
  }
}

enum AuthForgotPasswordStatus { idle, sendingReset }

enum AuthForgotPasswordEmailError { invalid }

enum AuthForgotPasswordGlobalError { supabaseUnavailable }

enum AuthForgotPasswordNotice { resetEmailSent }

typedef AuthForgotPasswordResetSender = Future<void> Function(String email);

final authForgotPasswordResetSenderProvider =
    Provider<AuthForgotPasswordResetSender?>((ref) {
      final client = ref.watch(supabaseClientProvider);
      if (client == null) return null;
      return (email) => client.auth.resetPasswordForEmail(
        email,
        redirectTo: _passwordRecoveryRedirectTo,
      );
    });

String _passwordRecoverySchemeForEnvironment() {
  final env = EnvironmentLoader().load().environment;
  return switch (env) {
    AppEnvironment.prod => 'movi',
    AppEnvironment.staging => 'movi-staging',
    AppEnvironment.dev => 'movi-dev',
  };
}

String get _passwordRecoveryRedirectTo =>
    '${_passwordRecoverySchemeForEnvironment()}://auth${AppRoutePaths.authUpdatePasswordCallback}';

class AuthForgotPasswordController extends Notifier<AuthForgotPasswordState> {
  @override
  AuthForgotPasswordState build() => const AuthForgotPasswordState();

  void setEmail(String raw) {
    final normalized = raw.trim().toLowerCase();
    state = state.copyWith(
      email: normalized,
      emailError: null,
      globalError: null,
      globalErrorKey: null,
      noticeKey: null,
    );
  }

  bool _validateEmail() {
    final email = state.email;
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      state = state.copyWith(emailError: AuthForgotPasswordEmailError.invalid);
      return false;
    }
    return true;
  }

  Future<bool> sendPasswordReset() async {
    if (state.status == AuthForgotPasswordStatus.sendingReset) {
      return false;
    }

    if (!_validateEmail()) {
      return false;
    }

    final resetSender = ref.read(authForgotPasswordResetSenderProvider);
    if (resetSender == null) {
      state = state.copyWith(
        globalErrorKey: AuthForgotPasswordGlobalError.supabaseUnavailable,
        globalError: null,
        noticeKey: null,
      );
      return false;
    }

    state = state.copyWith(
      status: AuthForgotPasswordStatus.sendingReset,
      globalError: null,
      globalErrorKey: null,
      noticeKey: null,
    );

    try {
      await resetSender(state.email);
      state = state.copyWith(
        status: AuthForgotPasswordStatus.idle,
        noticeKey: AuthForgotPasswordNotice.resetEmailSent,
      );
      return true;
    } catch (error, stackTrace) {
      // Preserve anti-enumeration by returning the same user-facing notice.
      mapSupabaseError(error, stackTrace: stackTrace);
      state = state.copyWith(
        status: AuthForgotPasswordStatus.idle,
        globalError: null,
        globalErrorKey: null,
        noticeKey: AuthForgotPasswordNotice.resetEmailSent,
      );
      return true;
    }
  }
}

final authForgotPasswordControllerProvider =
    NotifierProvider<AuthForgotPasswordController, AuthForgotPasswordState>(
      AuthForgotPasswordController.new,
    );
