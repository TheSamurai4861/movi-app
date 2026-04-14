import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/auth/domain/entities/auth_models.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/presentation/focus_directional_navigation.dart';
import 'package:movi/src/shared/widgets/app_labeled_text_field.dart';
import 'package:movi/src/core/focus/presentation/focus_region_scope.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/core/auth/presentation/providers/auth_providers.dart';
import 'package:movi/src/features/auth/presentation/auth_otp_controller.dart';
import 'package:movi/src/features/welcome/presentation/widgets/welcome_header.dart';

class AuthOtpPage extends ConsumerStatefulWidget {
  const AuthOtpPage({super.key, this.returnOnSuccess = false});

  final bool returnOnSuccess;

  @override
  ConsumerState<AuthOtpPage> createState() => _AuthOtpPageState();
}

class _AuthOtpPageState extends ConsumerState<AuthOtpPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  final _emailFocusNode = FocusNode(debugLabel: 'AuthOtpEmail');
  final _codeFocusNode = FocusNode(debugLabel: 'AuthOtpCode');
  final _primaryActionFocusNode = FocusNode(debugLabel: 'AuthOtpPrimaryAction');
  final _resendFocusNode = FocusNode(debugLabel: 'AuthOtpResend');
  final _changeEmailFocusNode = FocusNode(debugLabel: 'AuthOtpChangeEmail');
  bool _handledSuccessfulAuth = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _emailFocusNode.dispose();
    _codeFocusNode.dispose();
    _primaryActionFocusNode.dispose();
    _resendFocusNode.dispose();
    _changeEmailFocusNode.dispose();
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
    final state = ref.watch(authOtpControllerProvider);
    final authStatus = ref.watch(authStatusProvider);

    final emailErrorText = switch (state.emailError) {
      AuthOtpEmailError.invalid => l10n.errorFillFields,
      null => null,
    };

    final globalErrorText =
        state.globalError ??
        switch (state.globalErrorKey) {
          AuthOtpGlobalError.supabaseUnavailable => l10n.errorConnectionGeneric,
          null => null,
        };

    // Réagir à l'auth globale : dès que l'utilisateur est authentifié,
    // on relance le flux de launch pour recalculer la destination réelle.
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

    final isSending = state.status == AuthOtpStatus.sendingCode;
    final isVerifying = state.status == AuthOtpStatus.verifyingCode;
    final isBusy = isSending || isVerifying;
    final isCodeStepVisible =
        state.status == AuthOtpStatus.codeSent ||
        isVerifying ||
        state.cooldownRemaining > 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: FocusRegionScope(
        regionId: AppFocusRegionId.authOtpPrimary,
        binding: FocusRegionBinding(
          resolvePrimaryEntryNode: () => isCodeStepVisible
              ? _codeFocusNode
              : _emailFocusNode,
          resolveFallbackEntryNode: () => _primaryActionFocusNode,
        ),
        requestFocusOnMount: true,
        handleDirectionalExits: false,
        debugLabel: 'AuthOtpRegion',
        child: Focus(
          canRequestFocus: false,
          onKeyEvent: (_, event) => _handleRouteBackKey(event, context),
          child: Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      WelcomeHeader(
                        title: l10n.authOtpTitle,
                        subtitle: l10n.authOtpSubtitle,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Step 1 — Email
                          AppLabeledTextField(
                            label: l10n.authOtpEmailLabel,
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            enabled: !isBusy,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            hintText: l10n.authOtpEmailHint,
                            helpText: l10n.authOtpEmailHelp,
                            errorText: emailErrorText,
                            enableFocusWrapper: true,
                            verticalAlignment: 0.4,
                            nextDownFocus: isCodeStepVisible
                                ? _codeFocusNode
                                : _primaryActionFocusNode,
                            blockUp: true,
                            onChanged: (value) {
                              ref
                                  .read(authOtpControllerProvider.notifier)
                                  .setEmail(value);
                            },
                            onFieldSubmitted: (_) {
                              if (!isCodeStepVisible) {
                                _onSendCode();
                              } else {
                                _codeFocusNode.requestFocus();
                              }
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Step 2 — Code OTP
                          if (isCodeStepVisible) ...[
                            AppLabeledTextField(
                              label: l10n.authOtpCodeLabel,
                              controller: _codeController,
                              focusNode: _codeFocusNode,
                              enabled: !isBusy,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              maxLength: 8,
                              counterText: '',
                              autofillHints: const [AutofillHints.oneTimeCode],
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              hintText: l10n.authOtpCodeHint,
                              helpText: l10n.authOtpCodeHelp,
                              errorText: state.codeError,
                              showHelpTextWhenError: true,
                              enableFocusWrapper: true,
                              verticalAlignment: 0.22,
                              nextUpFocus: _emailFocusNode,
                              nextDownFocus: _primaryActionFocusNode,
                              onChanged: (value) {
                                ref
                                    .read(authOtpControllerProvider.notifier)
                                    .setCode(value);
                              },
                              onFieldSubmitted: (_) => _onVerifyCode(),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],

                          if (globalErrorText != null) ...[
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
                            const SizedBox(height: AppSpacing.md),
                          ],

                          // 32px d'espacement entre le champ email et le bouton
                          const SizedBox(height: 32),

                          // Primary action button
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            child: MoviEnsureVisibleOnFocus(
                              verticalAlignment: 0.22,
                              child: Focus(
                                canRequestFocus: false,
                                onKeyEvent: (_, event) => FocusDirectionalNavigation.handleDirectionalKey(
                                  event,
                                  up: isCodeStepVisible
                                      ? _codeFocusNode
                                      : _emailFocusNode,
                                  down: isCodeStepVisible
                                      ? _resendFocusNode
                                      : null,
                                  blockDown: !isCodeStepVisible,
                                  blockLeft: true,
                                  blockRight: true,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: MoviPrimaryButton(
                                    focusNode: _primaryActionFocusNode,
                                    label: isCodeStepVisible
                                        ? l10n.authOtpPrimarySubmit
                                        : l10n.authOtpPrimarySend,
                                    loading: isBusy,
                                    onPressed: isBusy
                                        ? null
                                        : () {
                                            if (isCodeStepVisible) {
                                              _onVerifyCode();
                                            } else {
                                              _onSendCode();
                                            }
                                          },
                                  ),
                                ),
                              ),
                            ),
                          ),

                          if (isCodeStepVisible) ...[
                            const SizedBox(height: AppSpacing.md),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final bool isNarrow =
                                      constraints.maxWidth < 360;

                                  final resendButton = SizedBox(
                                    width: double.infinity,
                                    child: MoviEnsureVisibleOnFocus(
                                      verticalAlignment: 0.22,
                                      child: Focus(
                                        canRequestFocus: false,
                                        onKeyEvent: (_, event) =>
                                            FocusDirectionalNavigation.handleDirectionalKey(
                                              event,
                                              right: isNarrow
                                                  ? null
                                                  : _changeEmailFocusNode,
                                              up: _primaryActionFocusNode,
                                              down: isNarrow
                                                  ? _changeEmailFocusNode
                                                  : null,
                                              blockLeft: true,
                                              blockDown: !isNarrow,
                                            ),
                                        child: TextButton(
                                          focusNode: _resendFocusNode,
                                          onPressed:
                                              state.cooldownRemaining == 0 &&
                                                  !isBusy
                                              ? _onResendCode
                                              : null,
                                          child: Text(
                                            state.cooldownRemaining > 0
                                                ? l10n.authOtpResendDisabled(
                                                    state.cooldownRemaining,
                                                  )
                                                : l10n.authOtpResend,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );

                                  final changeEmailButton = SizedBox(
                                    width: double.infinity,
                                    child: MoviEnsureVisibleOnFocus(
                                      verticalAlignment: 0.22,
                                      child: Focus(
                                        canRequestFocus: false,
                                        onKeyEvent: (_, event) =>
                                            FocusDirectionalNavigation.handleDirectionalKey(
                                              event,
                                              left: isNarrow
                                                  ? null
                                                  : _resendFocusNode,
                                              up: isNarrow
                                                  ? _resendFocusNode
                                                  : _primaryActionFocusNode,
                                              blockRight: true,
                                              blockDown: true,
                                              blockLeft: !isNarrow,
                                            ),
                                        child: TextButton(
                                          focusNode: _changeEmailFocusNode,
                                          onPressed: isBusy
                                              ? null
                                              : _onChangeEmail,
                                          child: Text(l10n.authOtpChangeEmail),
                                        ),
                                      ),
                                    ),
                                  );

                                  if (isNarrow) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        resendButton,
                                        const SizedBox(height: AppSpacing.xs),
                                        changeEmailButton,
                                      ],
                                    );
                                  }

                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: resendButton),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(child: changeEmailButton),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
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

  void _onSendCode() {
    final controller = ref.read(authOtpControllerProvider.notifier);
    controller.sendCode().then((success) {
      if (success && mounted) {
        FocusScope.of(context).requestFocus(_codeFocusNode);
      }
    });
  }

  void _onVerifyCode() {
    ref.read(authOtpControllerProvider.notifier).verifyCode();
  }

  void _onResendCode() {
    ref.read(authOtpControllerProvider.notifier).resendCode();
  }

  void _onChangeEmail() {
    _codeController.clear();
    ref.read(authOtpControllerProvider.notifier).resetToEmailStep();
    FocusScope.of(context).requestFocus(_emailFocusNode);
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
