import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/auth/presentation/providers/auth_providers.dart';
import 'package:movi/src/core/supabase/supabase_error_mapper.dart';

@immutable
class AuthPasswordState {
  const AuthPasswordState({
    this.status = AuthPasswordStatus.idle,
    this.email = '',
    this.password = '',
    this.emailError,
    this.passwordError,
    this.globalErrorKey,
    this.globalError,
  });

  final AuthPasswordStatus status;
  final String email;
  final String password;

  final AuthPasswordEmailError? emailError;
  final AuthPasswordPasswordError? passwordError;
  final AuthPasswordGlobalError? globalErrorKey;
  final String? globalError;

  static const Object _unset = Object();

  AuthPasswordState copyWith({
    AuthPasswordStatus? status,
    String? email,
    String? password,
    Object? emailError = _unset,
    Object? passwordError = _unset,
    Object? globalErrorKey = _unset,
    Object? globalError = _unset,
  }) {
    return AuthPasswordState(
      status: status ?? this.status,
      email: email ?? this.email,
      password: password ?? this.password,
      emailError: identical(emailError, _unset)
          ? this.emailError
          : emailError as AuthPasswordEmailError?,
      passwordError: identical(passwordError, _unset)
          ? this.passwordError
          : passwordError as AuthPasswordPasswordError?,
      globalErrorKey: identical(globalErrorKey, _unset)
          ? this.globalErrorKey
          : globalErrorKey as AuthPasswordGlobalError?,
      globalError: identical(globalError, _unset)
          ? this.globalError
          : globalError as String?,
    );
  }
}

enum AuthPasswordStatus { idle, signingIn }

enum AuthPasswordEmailError { invalid }

enum AuthPasswordPasswordError { required }

enum AuthPasswordGlobalError { supabaseUnavailable }

class AuthPasswordController extends Notifier<AuthPasswordState> {
  @override
  AuthPasswordState build() => const AuthPasswordState();

  void setEmail(String raw) {
    final normalized = raw.trim().toLowerCase();
    state = state.copyWith(
      email: normalized,
      emailError: null,
      globalError: null,
      globalErrorKey: null,
    );
  }

  void setPassword(String raw) {
    state = state.copyWith(
      password: raw,
      passwordError: null,
      globalError: null,
      globalErrorKey: null,
    );
  }

  bool _validateEmail() {
    final email = state.email;
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      state = state.copyWith(emailError: AuthPasswordEmailError.invalid);
      return false;
    }
    return true;
  }

  bool _validatePassword() {
    if (state.password.isEmpty) {
      state = state.copyWith(passwordError: AuthPasswordPasswordError.required);
      return false;
    }
    return true;
  }

  Future<bool> signIn() async {
    if (state.status == AuthPasswordStatus.signingIn) {
      return false;
    }

    final emailValid = _validateEmail();
    final passwordValid = _validatePassword();
    if (!emailValid || !passwordValid) {
      return false;
    }

    state = state.copyWith(
      status: AuthPasswordStatus.signingIn,
      globalError: null,
      globalErrorKey: null,
    );

    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithPassword(email: state.email, password: state.password);
      state = state.copyWith(status: AuthPasswordStatus.idle);
      return true;
    } catch (error, stackTrace) {
      final failure = mapSupabaseError(error, stackTrace: stackTrace);
      state = state.copyWith(
        status: AuthPasswordStatus.idle,
        globalError: failure.message,
        globalErrorKey: null,
      );
      return false;
    }
  }
}

final authPasswordControllerProvider =
    NotifierProvider<AuthPasswordController, AuthPasswordState>(
      AuthPasswordController.new,
    );
