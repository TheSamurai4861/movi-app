import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/router/app_route_paths.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/features/auth/presentation/auth_forgot_password_controller.dart';
import 'package:movi/src/features/welcome/presentation/widgets/welcome_header.dart';
import 'package:movi/src/shared/widgets/app_labeled_text_field.dart';

class AuthForgotPasswordPage extends ConsumerStatefulWidget {
  const AuthForgotPasswordPage({super.key});

  @override
  ConsumerState<AuthForgotPasswordPage> createState() =>
      _AuthForgotPasswordPageState();
}

class _AuthForgotPasswordPageState
    extends ConsumerState<AuthForgotPasswordPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(authForgotPasswordControllerProvider);

    if (_emailController.text != state.email) {
      _emailController.value = TextEditingValue(
        text: state.email,
        selection: TextSelection.collapsed(offset: state.email.length),
      );
    }

    final emailErrorText = switch (state.emailError) {
      AuthForgotPasswordEmailError.invalid => l10n.errorFillFields,
      null => null,
    };
    final globalErrorText =
        state.globalError ??
        switch (state.globalErrorKey) {
          AuthForgotPasswordGlobalError.supabaseUnavailable =>
            l10n.errorConnectionGeneric,
          null => null,
        };
    final noticeText = switch (state.noticeKey) {
      AuthForgotPasswordNotice.resetEmailSent => l10n.authPasswordResetSent,
      null => null,
    };

    final isBusy = state.status == AuthForgotPasswordStatus.sendingReset;

    return Scaffold(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WelcomeHeader(
                    title: l10n.authForgotPasswordTitle,
                    subtitle: l10n.authForgotPasswordSubtitle,
                    adaptLogoToNarrowScreen: true,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppLabeledTextField(
                    label: l10n.authPasswordEmailLabel,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    hintText: l10n.authPasswordEmailHint,
                    errorText: emailErrorText,
                    decoration: _buildAuthInputDecoration(context),
                    onChanged: (value) {
                      ref
                          .read(authForgotPasswordControllerProvider.notifier)
                          .setEmail(value);
                    },
                    onFieldSubmitted: (_) => _onSendLink(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Text(
                      l10n.authForgotPasswordInfoNeutral,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  if (globalErrorText != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Text(
                        globalErrorText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                  if (noticeText != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Text(
                        noticeText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: MoviPrimaryButton(
                      label: l10n.authForgotPasswordPrimarySubmit,
                      loading: isBusy,
                      onPressed: isBusy ? null : _onSendLink,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: TextButton(
                      onPressed: isBusy ? null : _onBackToSignIn,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 40),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(l10n.authForgotPasswordBackToSignIn),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onSendLink() {
    ref.read(authForgotPasswordControllerProvider.notifier).sendPasswordReset();
  }

  void _onBackToSignIn() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    context.go(AppRoutePaths.authOtp);
  }

  InputDecoration _buildAuthInputDecoration(BuildContext context) {
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
    );
  }
}
