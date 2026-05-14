import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/router/app_route_paths.dart';
import 'package:movi/src/core/startup/presentation/widgets/boot_form_tokens.dart';
import 'package:movi/src/core/supabase/supabase_error_mapper.dart';
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

  _ForgotPasswordStep _step = _ForgotPasswordStep.email;
  bool _isBusy = false;

  String? _emailErrorText;
  String? _globalErrorText;
  String? _noticeText;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  WelcomeHeader(
                    title: 'Mot de passe oublie',
                    subtitle: _subtitleForStep(),
                    adaptLogoToNarrowScreen: true,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_step == _ForgotPasswordStep.email) _buildEmailStep(context),
                  if (_step == _ForgotPasswordStep.linkSent)
                    _buildLinkSentStep(context),
                  const SizedBox(height: BootFormTokens.formElementGap),
                  Text(
                    'Vous vous souvenez du mot de passe ?',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  BootFormTokens.constrainPrimaryAction(
                    MoviPrimaryButton(
                      label: 'Se connecter',
                      loading: false,
                      onPressed: _isBusy ? null : _onBackToSignIn,
                      height: BootFormTokens.primaryActionHeight,
                      buttonStyle: BootFormTokens.bootPrimaryButtonStyle(
                        Theme.of(context),
                      ),
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

  Widget _buildEmailStep(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BootFormTokens.constrainTextField(
          AppLabeledTextField(
            label: l10n.authPasswordEmailLabel,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            hintText: l10n.authPasswordEmailHint,
            errorText: _emailErrorText,
            decoration: _buildAuthInputDecoration(context),
            onChanged: (_) {
              if (_emailErrorText != null ||
                  _globalErrorText != null ||
                  _noticeText != null) {
                setState(() {
                  _emailErrorText = null;
                  _globalErrorText = null;
                  _noticeText = null;
                });
              }
            },
            onFieldSubmitted: (_) => _onSendRequest(),
          ),
          alignLeft: true,
        ),
        if (_globalErrorText != null) ...[
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              _globalErrorText!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
        if (_noticeText != null) ...[
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              _noticeText!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
        const SizedBox(height: BootFormTokens.formElementGap),
        BootFormTokens.constrainPrimaryAction(
          MoviPrimaryButton(
            label: 'Envoyer la demande',
            loading: _isBusy,
            onPressed: _isBusy ? null : _onSendRequest,
            height: BootFormTokens.primaryActionHeight,
            buttonStyle: BootFormTokens.bootPrimaryButtonStyle(
              Theme.of(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkSentStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BootFormTokens.constrainTextField(
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(BootFormTokens.borderRadius),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Text(
              'Si un compte existe pour cette adresse, un lien de reinitialisation a ete envoye. '
              'Ouvrez ce lien pour definir un nouveau mot de passe.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          alignLeft: true,
        ),
        const SizedBox(height: BootFormTokens.formElementGap),
        BootFormTokens.constrainPrimaryAction(
          MoviPrimaryButton(
            label: 'Renvoyer la demande',
            loading: _isBusy,
            onPressed: _isBusy ? null : _onSendRequest,
            height: BootFormTokens.primaryActionHeight,
            buttonStyle: BootFormTokens.bootPrimaryButtonStyle(
              Theme.of(context),
            ),
          ),
        ),
      ],
    );
  }

  String _subtitleForStep() {
    return switch (_step) {
      _ForgotPasswordStep.email =>
        'Renseignez votre adresse mail pour reinitialiser votre mot de passe',
      _ForgotPasswordStep.linkSent =>
        'Consultez votre email puis suivez le lien de reinitialisation.',
    };
  }

  Future<void> _onSendRequest() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() {
        _emailErrorText = 'Adresse email invalide.';
      });
      return;
    }

    final resetSender = ref.read(authForgotPasswordResetSenderProvider);
    if (resetSender == null) {
      setState(() {
        _globalErrorText = 'Service indisponible pour le moment.';
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _emailErrorText = null;
      _globalErrorText = null;
      _noticeText = null;
    });

    try {
      await resetSender(email);
    } catch (error, stackTrace) {
      // Keep anti-enumeration behavior: return same user-facing flow.
      mapSupabaseError(error, stackTrace: stackTrace);
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _step = _ForgotPasswordStep.linkSent;
          _noticeText =
              'Si un compte existe pour cette adresse, un email de reinitialisation a ete envoye.';
        });
      }
    }
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
    return BootFormTokens.bootTextFieldDecoration(theme).copyWith(
      suffixIconColor: scheme.onSurfaceVariant,
    );
  }
}

enum _ForgotPasswordStep { email, linkSent }
