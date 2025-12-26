import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/auth/domain/entities/auth_models.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/core/auth/presentation/providers/auth_providers.dart';
import 'package:movi/src/features/auth/presentation/auth_otp_controller.dart';
import 'package:movi/src/features/welcome/presentation/widgets/labeled_field.dart';
import 'package:movi/src/features/welcome/presentation/widgets/welcome_header.dart';

class AuthOtpPage extends ConsumerStatefulWidget {
  const AuthOtpPage({super.key});

  @override
  ConsumerState<AuthOtpPage> createState() => _AuthOtpPageState();
}

class _AuthOtpPageState extends ConsumerState<AuthOtpPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _codeFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _emailFocusNode.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(authOtpControllerProvider);

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
    // on le redirige vers l'écran Welcome (création / sélection de profil).
    ref.listen<AuthStatus>(
      authStatusProvider,
      (previous, next) {
        if (previous != AuthStatus.authenticated &&
            next == AuthStatus.authenticated &&
            mounted) {
          context.go(AppRouteNames.welcome);
        }
      },
    );

    final isSending = state.status == AuthOtpStatus.sendingCode;
    final isVerifying = state.status == AuthOtpStatus.verifyingCode;
    final isBusy = isSending || isVerifying;
    final isCodeStepVisible =
        state.status == AuthOtpStatus.codeSent || isVerifying || state.cooldownRemaining > 0;

    return Scaffold(
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
                      LabeledField(
                        label: l10n.authOtpEmailLabel,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              enabled: !isBusy,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
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
                              decoration: InputDecoration(
                                hintText: l10n.authOtpEmailHint,
                                errorText: emailErrorText,
                              ),
                            ),
                            if (emailErrorText == null) ...[
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 12, right: 12),
                                child: Text(
                                  l10n.authOtpEmailHelp,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  softWrap: true,
                                  maxLines: 3,
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Step 2 — Code OTP
                      if (isCodeStepVisible) ...[
                        LabeledField(
                          label: l10n.authOtpCodeLabel,
                          child: TextFormField(
                            controller: _codeController,
                            focusNode: _codeFocusNode,
                            enabled: !isBusy,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            maxLength: 8,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) {
                              ref
                                  .read(authOtpControllerProvider.notifier)
                                  .setCode(value);
                            },
                            onFieldSubmitted: (_) => _onVerifyCode(),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: l10n.authOtpCodeHint,
                              helperText: l10n.authOtpCodeHelp,
                              errorText: state.codeError,
                            ),
                          ),
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
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Theme.of(context).colorScheme.error),
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
                        child: SizedBox(
                          width: double.infinity,
                          child: MoviPrimaryButton(
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

                      if (isCodeStepVisible) ...[
                        const SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final bool isNarrow = constraints.maxWidth < 360;

                              final resendButton = SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed: state.cooldownRemaining == 0 && !isBusy
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
                              );

                              final changeEmailButton = SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed: isBusy ? null : _onChangeEmail,
                                  child: Text(l10n.authOtpChangeEmail),
                                ),
                              );

                              if (isNarrow) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    resendButton,
                                    const SizedBox(height: AppSpacing.xs),
                                    changeEmailButton,
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
}


