import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/core/router/app_route_paths.dart';
import 'package:movi/src/core/supabase/supabase_error_mapper.dart';
import 'package:movi/src/core/supabase/supabase_providers.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/shared/widgets/app_labeled_text_field.dart';
import 'package:movi/src/features/welcome/presentation/widgets/welcome_header.dart';

typedef AuthUpdatePasswordSubmitter = Future<void> Function(String password);

final authUpdatePasswordSubmitterProvider =
    Provider<AuthUpdatePasswordSubmitter?>((ref) {
      final client = ref.watch(supabaseClientProvider);
      if (client == null) return null;
      return (password) =>
          client.auth.updateUser(UserAttributes(password: password));
    });

/// Update-password screen used by the recovery callback route.
class AuthUpdatePasswordPage extends ConsumerStatefulWidget {
  const AuthUpdatePasswordPage({super.key});

  @override
  ConsumerState<AuthUpdatePasswordPage> createState() =>
      _AuthUpdatePasswordPageState();
}

enum _UpdatePasswordStatus { idle, loading, success, error }

class _AuthUpdatePasswordPageState
    extends ConsumerState<AuthUpdatePasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _UpdatePasswordStatus _status = _UpdatePasswordStatus.idle;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _globalMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_status == _UpdatePasswordStatus.loading) return;

    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    String? passwordError;
    String? confirmError;
    String? globalMessage;

    if (password.isEmpty) {
      passwordError = 'Veuillez saisir un nouveau mot de passe.';
    } else if (password.length < 8) {
      passwordError = 'Le mot de passe doit contenir au moins 8 caracteres.';
    }

    if (confirm.isEmpty) {
      confirmError = 'Veuillez confirmer le mot de passe.';
    } else if (password != confirm) {
      confirmError = 'Les mots de passe ne correspondent pas.';
    }

    if (passwordError != null || confirmError != null) {
      setState(() {
        _status = _UpdatePasswordStatus.error;
        _passwordError = passwordError;
        _confirmPasswordError = confirmError;
        _globalMessage = 'Corrigez les champs puis reessayez.';
      });
      return;
    }

    setState(() {
      _status = _UpdatePasswordStatus.loading;
      _passwordError = null;
      _confirmPasswordError = null;
      _globalMessage = null;
    });

    final submitter = ref.read(authUpdatePasswordSubmitterProvider);
    if (submitter == null) {
      setState(() {
        _status = _UpdatePasswordStatus.error;
        _globalMessage =
            'Service indisponible pour le moment. Reessayez plus tard.';
      });
      return;
    }

    try {
      await submitter(password);
      if (!mounted) return;
      globalMessage = 'Mot de passe mis a jour. Vous pouvez vous reconnecter.';
      setState(() {
        _status = _UpdatePasswordStatus.success;
        _globalMessage = globalMessage;
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      final failure = mapSupabaseError(error, stackTrace: stackTrace);
      final lowered = failure.message.toLowerCase();
      final isRecoverySessionIssue =
          lowered.contains('expired') ||
          lowered.contains('invalid') ||
          lowered.contains('session');

      setState(() {
        _status = _UpdatePasswordStatus.error;
        _globalMessage = isRecoverySessionIssue
            ? 'Le lien de recuperation est invalide ou expire. Demandez un nouveau lien.'
            : 'Impossible de mettre a jour le mot de passe. Reessayez.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBusy = _status == _UpdatePasswordStatus.loading;

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
                  const WelcomeHeader(
                    title: 'Mise a jour du mot de passe',
                    subtitle:
                        'Saisissez un nouveau mot de passe pour securiser votre compte.',
                    adaptLogoToNarrowScreen: true,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppLabeledTextField(
                    label: 'Nouveau mot de passe',
                    controller: _passwordController,
                    enabled: !isBusy,
                    hintText: 'Saisissez votre nouveau mot de passe',
                    helpText:
                        'Utilisez au minimum 8 caracteres pour un mot de passe robuste.',
                    errorText: _passwordError,
                    obscureText: !_isPasswordVisible,
                    showHelpTextWhenError: true,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        onPressed: isBusy
                            ? null
                            : () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
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
                    onChanged: (_) {
                      if (_status == _UpdatePasswordStatus.error &&
                          (_passwordError != null || _globalMessage != null)) {
                        setState(() {
                          _passwordError = null;
                          if (_confirmPasswordError == null) {
                            _globalMessage = null;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppLabeledTextField(
                    label: 'Confirmer le mot de passe',
                    controller: _confirmPasswordController,
                    enabled: !isBusy,
                    hintText: 'Resaisissez le nouveau mot de passe',
                    errorText: _confirmPasswordError,
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        onPressed: isBusy
                            ? null
                            : () {
                                setState(() {
                                  _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible;
                                });
                              },
                        tooltip: _isConfirmPasswordVisible
                            ? 'Masquer le mot de passe'
                            : 'Afficher le mot de passe',
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                      ),
                    ),
                    onChanged: (_) {
                      if (_status == _UpdatePasswordStatus.error &&
                          (_confirmPasswordError != null ||
                              _globalMessage != null)) {
                        setState(() {
                          _confirmPasswordError = null;
                          if (_passwordError == null) {
                            _globalMessage = null;
                          }
                        });
                      }
                    },
                    onFieldSubmitted: (_) => _onSubmit(),
                  ),
                  if (_globalMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Text(
                        _globalMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: switch (_status) {
                            _UpdatePasswordStatus.success =>
                              theme.colorScheme.primary,
                            _ => theme.colorScheme.error,
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  MoviPrimaryButton(
                    label: 'Mettre a jour',
                    loading: isBusy,
                    onPressed: isBusy ? null : _onSubmit,
                  ),
                  if (_status == _UpdatePasswordStatus.success) ...[
                    const SizedBox(height: AppSpacing.md),
                    MoviPrimaryButton(
                      label: 'Aller a la connexion',
                      onPressed: () => context.go(AppRoutePaths.authOtp),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
