import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/auth/domain/entities/auth_models.dart';
import 'package:movi/src/core/auth/presentation/providers/auth_providers.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/presentation/focus_directional_navigation.dart';
import 'package:movi/src/core/focus/presentation/focus_region_scope.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/startup/presentation/boot_action_executor.dart';
import 'package:movi/src/core/startup/presentation/boot_action_handler.dart';
import 'package:movi/src/core/startup/presentation/widgets/boot_form_tokens.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/features/auth/presentation/auth_password_controller.dart';
import 'package:movi/src/features/welcome/presentation/widgets/welcome_header.dart';
import 'package:movi/src/shared/widgets/app_labeled_text_field.dart';

class AuthPasswordPage extends ConsumerStatefulWidget {
  const AuthPasswordPage({super.key, this.returnOnSuccess = false});

  final bool returnOnSuccess;

  @override
  ConsumerState<AuthPasswordPage> createState() => _AuthPasswordPageState();
}

class _AuthPasswordPageState extends ConsumerState<AuthPasswordPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocusNode = FocusNode(debugLabel: 'AuthPasswordEmail');
  final _passwordFocusNode = FocusNode(debugLabel: 'AuthPasswordPassword');
  final _primaryActionFocusNode = FocusNode(
    debugLabel: 'AuthPasswordPrimaryAction',
  );
  final _forgotPasswordFocusNode = FocusNode(
    debugLabel: 'AuthPasswordForgotPassword',
  );
  final _signUpFocusNode = FocusNode(debugLabel: 'AuthPasswordSignUp');
  final _otpFallbackFocusNode = FocusNode(debugLabel: 'AuthPasswordUseOtp');

  bool _handledSuccessfulAuth = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _primaryActionFocusNode.dispose();
    _forgotPasswordFocusNode.dispose();
    _signUpFocusNode.dispose();
    _otpFallbackFocusNode.dispose();
    super.dispose();
  }

  bool _handleBack(BuildContext context) {
    if (!context.mounted) {
      return false;
    }
    final navigator = Navigator.of(context);
    if (!navigator.canPop()) {
      return false;
    }
    navigator.maybePop();
    return true;
  }

  KeyEventResult _handleRouteBackKey(KeyEvent event, BuildContext context) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.escape) {
      return _handleBack(context)
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(authPasswordControllerProvider);
    final authStatus = ref.watch(authStatusProvider);

    final emailErrorText = switch (state.emailError) {
      AuthPasswordEmailError.invalid => l10n.errorFillFields,
      null => null,
    };

    final passwordErrorText = switch (state.passwordError) {
      AuthPasswordPasswordError.required => l10n.errorFillFields,
      null => null,
    };

    final globalErrorText =
        state.globalError ??
        switch (state.globalErrorKey) {
          AuthPasswordGlobalError.supabaseUnavailable =>
            l10n.errorConnectionGeneric,
          null => null,
        };

    ref.listen<AuthStatus>(authStatusProvider, (previous, next) {
      if (previous != AuthStatus.authenticated &&
          next == AuthStatus.authenticated &&
          mounted) {
        _handleSuccessfulAuthentication();
      }
    });

    if (widget.returnOnSuccess &&
        authStatus == AuthStatus.authenticated &&
        !_handledSuccessfulAuth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _handleSuccessfulAuthentication();
      });
    }

    final isSigningIn = state.status == AuthPasswordStatus.signingIn;
    final isBusy = isSigningIn;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: FocusRegionScope(
        regionId: AppFocusRegionId.authOtpPrimary,
        binding: FocusRegionBinding(
          resolvePrimaryEntryNode: () => _emailFocusNode,
          resolveFallbackEntryNode: () => _primaryActionFocusNode,
        ),
        requestFocusOnMount: true,
        handleDirectionalExits: false,
        debugLabel: 'AuthPasswordRegion',
        child: Focus(
          canRequestFocus: false,
          onKeyEvent: (_, event) => _handleRouteBackKey(event, context),
          child: Scaffold(
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: BootFormTokens.textFieldMaxWidth,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl,
                      horizontal: AppSpacing.md,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                              BootFormTokens.constrainTextField(
                                const WelcomeHeader(
                                  title: 'Connexion à Movi',
                                  subtitle: 'Connectez vous à votre compte Movi.',
                                  adaptLogoToNarrowScreen: true,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                            BootFormTokens.constrainTextField(
                              AppLabeledTextField(
                                label: l10n.authPasswordEmailLabel,
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                enabled: !isBusy,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                hintText: l10n.authPasswordEmailHint,
                                errorText: emailErrorText,
                                decoration: _buildAuthInputDecoration(context),
                                enableFocusWrapper: true,
                                verticalAlignment: 0.4,
                                nextDownFocus: _passwordFocusNode,
                                blockUp: true,
                                onChanged: (value) {
                                  ref
                                      .read(
                                        authPasswordControllerProvider
                                            .notifier,
                                      )
                                      .setEmail(value);
                                },
                                onFieldSubmitted: (_) {
                                  _passwordFocusNode.requestFocus();
                                },
                              ),
                            ),
                            const SizedBox(height: BootFormTokens.formElementGap),
                            BootFormTokens.constrainTextField(
                              AppLabeledTextField(
                                label: l10n.authPasswordPasswordLabel,
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                enabled: !isBusy,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                hintText: l10n.authPasswordPasswordHint,
                                helpText: l10n.authPasswordPasswordHelp,
                                errorText: passwordErrorText,
                                obscureText: !_isPasswordVisible,
                                showHelpTextWhenError: true,
                                decoration: _buildAuthInputDecoration(
                                  context,
                                  suffixIcon: IconButton(
                                    onPressed: isBusy
                                        ? null
                                        : () {
                                            setState(() {
                                              _isPasswordVisible =
                                                  !_isPasswordVisible;
                                            });
                                          },
                                    tooltip: _isPasswordVisible
                                        ? 'Masquer le mot de passe'
                                        : 'Afficher le mot de passe',
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                enableFocusWrapper: true,
                                verticalAlignment: 0.22,
                                nextUpFocus: _emailFocusNode,
                                nextDownFocus: _primaryActionFocusNode,
                                onChanged: (value) {
                                  ref
                                      .read(
                                        authPasswordControllerProvider
                                            .notifier,
                                      )
                                      .setPassword(value);
                                },
                                onFieldSubmitted: (_) => _onSignIn(),
                              ),
                            ),
                            if (globalErrorText != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              BootFormTokens.constrainTextField(
                                Text(
                                  globalErrorText,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                ),
                              ),
                            ],
                                  const SizedBox(height: AppSpacing.md),
                                  BootFormTokens.constrainTextField(
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton(
                                        focusNode: _forgotPasswordFocusNode,
                                        onPressed: isBusy
                                            ? null
                                            : _onForgotPassword,
                                        style: TextButton.styleFrom(
                                          foregroundColor: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(0, 40),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        child: Text(
                                          l10n.authPasswordForgotPassword,
                                          style: const TextStyle(
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: BootFormTokens.formElementGap),
                            MoviEnsureVisibleOnFocus(
                              verticalAlignment: 0.22,
                              child: Focus(
                                canRequestFocus: false,
                                onKeyEvent: (_, event) =>
                                    FocusDirectionalNavigation.handleDirectionalKey(
                                      event,
                                      up: _forgotPasswordFocusNode,
                                      down: _signUpFocusNode,
                                      blockLeft: true,
                                      blockRight: true,
                                    ),
                                child: BootFormTokens.constrainPrimaryAction(
                                  MoviPrimaryButton(
                                    focusNode: _primaryActionFocusNode,
                                    label: l10n.authPasswordPrimarySubmit,
                                    loading: isSigningIn,
                                    onPressed: isBusy ? null : _onSignIn,
                                    height: BootFormTokens.primaryActionHeight,
                                    buttonStyle:
                                        BootFormTokens.bootPrimaryButtonStyle(
                                      Theme.of(context),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                                ],
                              ),
                              const SizedBox(height: BootFormTokens.formElementGap),
                              BootFormTokens.constrainTextField(
                                Text(
                                  'Vous n’avez pas de compte ?',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              MoviEnsureVisibleOnFocus(
                                verticalAlignment: 0.22,
                                child: Focus(
                                  canRequestFocus: false,
                                  onKeyEvent: (_, event) =>
                                      FocusDirectionalNavigation
                                          .handleDirectionalKey(
                                            event,
                                            up: _primaryActionFocusNode,
                                            blockDown: true,
                                            blockLeft: true,
                                            blockRight: true,
                                          ),
                                  child: BootFormTokens.constrainPrimaryAction(
                                    MoviPrimaryButton(
                                      focusNode: _signUpFocusNode,
                                      label: 'S\'inscrire',
                                      onPressed: isBusy ? null : _onSignUp,
                                      height: BootFormTokens.primaryActionHeight,
                                      buttonStyle:
                                          BootFormTokens.bootPrimaryButtonStyle(
                                        Theme.of(context),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              // Keep hidden fallback for keyboard shortcut coverage.
                            MoviEnsureVisibleOnFocus(
                              verticalAlignment: 0.22,
                              child: Focus(
                                canRequestFocus: false,
                                onKeyEvent: (_, event) =>
                                    FocusDirectionalNavigation.handleDirectionalKey(
                                      event,
                                      up: _signUpFocusNode,
                                      blockDown: true,
                                      blockLeft: true,
                                      blockRight: true,
                                    ),
                                child: const SizedBox.shrink(),
                              ),
                            ),
                            Offstage(
                              offstage: true,
                              child: TextButton(
                                focusNode: _otpFallbackFocusNode,
                                onPressed: isBusy ? null : _onUseOtpFallback,
                                child: Text(l10n.authPasswordUseOtp),
                              ),
                            ),
                            ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onSignIn() {
    ref.read(authPasswordControllerProvider.notifier).signIn();
  }

  void _onForgotPassword() {
    if (!mounted) return;
    context.push(AppRoutePaths.authForgotPassword);
  }

  void _onSignUp() {
    if (!mounted) return;
    context.push(AppRoutePaths.authSignUp);
  }

  InputDecoration _buildAuthInputDecoration(
    BuildContext context, {
    Widget? suffixIcon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return BootFormTokens.bootTextFieldDecoration(Theme.of(context)).copyWith(
      suffixIcon: suffixIcon,
      suffixIconColor: scheme.onSurfaceVariant,
    );
  }

  void _onUseOtpFallback() {
    if (!mounted) return;
    context.pushReplacement(_authLocation(otpMode: true));
  }

  String _authLocation({required bool otpMode}) {
    final query = <String, String>{
      if (otpMode) 'mode': 'otp',
      if (widget.returnOnSuccess) 'return_to': 'previous',
    };
    return Uri(
      path: AppRoutePaths.authOtp,
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }

  Future<void> _handleSuccessfulAuthentication() async {
    if (_handledSuccessfulAuth || !mounted) return;
    _handledSuccessfulAuth = true;

    final router = GoRouter.of(context);
    if (widget.returnOnSuccess && router.canPop()) {
      router.pop(true);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        executeBootAction(
          context,
          ref,
          const BootActionRequest(
            intent: BootActionIntent.retry,
            reasonCode: 'auth_completed',
          ),
        ),
      );
    });
  }
}
