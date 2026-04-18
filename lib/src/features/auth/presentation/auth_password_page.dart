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
import 'package:movi/src/core/utils/app_spacing.dart';
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
        event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
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
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl,
                      horizontal: AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        WelcomeHeader(
                          title: l10n.authPasswordTitle,
                          subtitle: l10n.authPasswordSubtitle,
                          adaptLogoToNarrowScreen: true,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                      authPasswordControllerProvider.notifier,
                                    )
                                    .setEmail(value);
                              },
                              onFieldSubmitted: (_) {
                                _passwordFocusNode.requestFocus();
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),
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
                                      authPasswordControllerProvider.notifier,
                                    )
                                    .setPassword(value);
                              },
                              onFieldSubmitted: (_) => _onSignIn(),
                            ),
                            if (globalErrorText != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                ),
                                child: Text(
                                  globalErrorText,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 32),
                            MoviEnsureVisibleOnFocus(
                              verticalAlignment: 0.22,
                              child: Focus(
                                canRequestFocus: false,
                                onKeyEvent: (_, event) =>
                                    FocusDirectionalNavigation.handleDirectionalKey(
                                      event,
                                      up: _passwordFocusNode,
                                      down: _forgotPasswordFocusNode,
                                      blockLeft: true,
                                      blockRight: true,
                                    ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: MoviPrimaryButton(
                                    focusNode: _primaryActionFocusNode,
                                    label: l10n.authPasswordPrimarySubmit,
                                    loading: isSigningIn,
                                    onPressed: isBusy ? null : _onSignIn,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            MoviEnsureVisibleOnFocus(
                              verticalAlignment: 0.22,
                              child: Focus(
                                canRequestFocus: false,
                                onKeyEvent: (_, event) =>
                                    FocusDirectionalNavigation.handleDirectionalKey(
                                      event,
                                      up: _primaryActionFocusNode,
                                      blockDown: true,
                                      blockLeft: true,
                                      blockRight: true,
                                    ),
                                child: Center(
                                  child: TextButton(
                                    focusNode: _forgotPasswordFocusNode,
                                    onPressed: isBusy
                                        ? null
                                        : _onForgotPassword,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 40),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    child: Text(
                                      l10n.authPasswordForgotPassword,
                                    ),
                                  ),
                                ),
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

  InputDecoration _buildAuthInputDecoration(
    BuildContext context, {
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    InputBorder border(Color color, {double width = 1}) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide(color: color, width: width),
    );

    return InputDecoration(
      filled: true,
      fillColor: scheme.surfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: border(scheme.outlineVariant),
      enabledBorder: border(scheme.outlineVariant),
      focusedBorder: border(scheme.primary, width: 2),
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

  void _handleSuccessfulAuthentication() {
    if (_handledSuccessfulAuth || !mounted) return;
    _handledSuccessfulAuth = true;

    final router = GoRouter.of(context);
    if (widget.returnOnSuccess && router.canPop()) {
      router.pop(true);
      return;
    }

    context.go(AppRoutePaths.launch);
  }
}
