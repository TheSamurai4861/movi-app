import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/presentation/focus_directional_navigation.dart';
import 'package:movi/src/core/focus/presentation/focus_region_scope.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/startup/presentation/widgets/boot_form_tokens.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/features/welcome/presentation/widgets/welcome_header.dart';
import 'package:movi/src/shared/widgets/app_labeled_text_field.dart';

class AuthSignUpPage extends ConsumerStatefulWidget {
  const AuthSignUpPage({super.key});

  @override
  ConsumerState<AuthSignUpPage> createState() => _AuthSignUpPageState();
}

class _AuthSignUpPageState extends ConsumerState<AuthSignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codeController = TextEditingController();

  final _emailFocusNode = FocusNode(debugLabel: 'AuthSignUpEmail');
  final _passwordFocusNode = FocusNode(debugLabel: 'AuthSignUpPassword');
  final _confirmPasswordFocusNode = FocusNode(
    debugLabel: 'AuthSignUpConfirmPassword',
  );
  final _primaryActionFocusNode = FocusNode(
    debugLabel: 'AuthSignUpPrimaryAction',
  );
  final _codeFocusNode = FocusNode(debugLabel: 'AuthSignUpCode');
  final _signInFocusNode = FocusNode(debugLabel: 'AuthSignUpSignIn');

  bool _isSubmitting = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  _SignUpStep _step = _SignUpStep.form;

  String? _emailErrorText;
  String? _passwordErrorText;
  String? _confirmPasswordErrorText;
  String? _codeErrorText;
  String? _globalErrorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _codeController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _primaryActionFocusNode.dispose();
    _codeFocusNode.dispose();
    _signInFocusNode.dispose();
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

  Future<void> _onSignUp() async {
    if (_isSubmitting) return;
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    String? emailError;
    String? passwordError;
    String? confirmError;

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      emailError = l10n.errorFillFields;
    }
    if (password.isEmpty) {
      passwordError = l10n.errorFillFields;
    }
    if (confirmPassword.isEmpty || confirmPassword != password) {
      confirmError = 'Les mots de passe ne correspondent pas.';
    }

    if (emailError != null || passwordError != null || confirmError != null) {
      setState(() {
        _emailErrorText = emailError;
        _passwordErrorText = passwordError;
        _confirmPasswordErrorText = confirmError;
        _globalErrorText = null;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _emailErrorText = null;
      _passwordErrorText = null;
      _confirmPasswordErrorText = null;
      _globalErrorText = null;
    });

    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      if (!mounted) return;
      setState(() {
        _step = _SignUpStep.confirmEmail;
        _codeController.clear();
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _globalErrorText = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _globalErrorText =
            'Impossible de créer le compte pour le moment. Réessayez.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _onConfirmEmail() async {
    if (_isSubmitting) return;
    final email = _emailController.text.trim().toLowerCase();
    final code = _codeController.text.trim();
    if (code.length != 8) {
      setState(() {
        _codeErrorText = 'Le code doit contenir 8 chiffres.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _codeErrorText = null;
      _globalErrorText = null;
    });

    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.signup,
      );
      if (!mounted) return;
      if (response.session == null) {
        setState(() {
          _codeErrorText = 'Code incorrect. Veuillez réessayer.';
        });
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email confirmé.')));
      context.pushReplacement(AppRoutePaths.authOtp);
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _globalErrorText = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _globalErrorText = 'Impossible de confirmer l’email pour le moment.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _onSignIn() {
    if (!mounted) return;
    context.pushReplacement(AppRoutePaths.authOtp);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: FocusRegionScope(
        regionId: AppFocusRegionId.authOtpPrimary,
        binding: FocusRegionBinding(
          resolvePrimaryEntryNode: () =>
              _step == _SignUpStep.form ? _emailFocusNode : _codeFocusNode,
          resolveFallbackEntryNode: () => _primaryActionFocusNode,
        ),
        requestFocusOnMount: true,
        handleDirectionalExits: false,
        debugLabel: 'AuthSignUpRegion',
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
                              WelcomeHeader(
                                title: 'Inscription à Movi',
                                subtitle: _step == _SignUpStep.form
                                    ? 'Créer votre compte Movi'
                                    : 'Nous vous avons envoyer un code à 8 chiffres par mail (vérifiez les spams). Entrez le pour vérifier votre email',
                                adaptLogoToNarrowScreen: true,
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_step == _SignUpStep.form) ...[
                                    BootFormTokens.constrainTextField(
                                      AppLabeledTextField(
                                        label: l10n.authPasswordEmailLabel,
                                        controller: _emailController,
                                        focusNode: _emailFocusNode,
                                        enabled: !_isSubmitting,
                                        keyboardType: TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        autofillHints: const [AutofillHints.email],
                                        hintText: l10n.authPasswordEmailHint,
                                        errorText: _emailErrorText,
                                        decoration: _buildAuthInputDecoration(
                                          context,
                                        ),
                                        enableFocusWrapper: true,
                                        verticalAlignment: 0.4,
                                        nextDownFocus: _passwordFocusNode,
                                        blockUp: true,
                                        onChanged: (_) {
                                          if (_emailErrorText != null ||
                                              _globalErrorText != null) {
                                            setState(() {
                                              _emailErrorText = null;
                                              _globalErrorText = null;
                                            });
                                          }
                                        },
                                        onFieldSubmitted: (_) {
                                          _passwordFocusNode.requestFocus();
                                        },
                                      ),
                                    ),
                                    const SizedBox(
                                      height: BootFormTokens.formElementGap,
                                    ),
                                    BootFormTokens.constrainTextField(
                                      AppLabeledTextField(
                                        label: l10n.authPasswordPasswordLabel,
                                        controller: _passwordController,
                                        focusNode: _passwordFocusNode,
                                        enabled: !_isSubmitting,
                                        textInputAction: TextInputAction.next,
                                        autofillHints: const [
                                          AutofillHints.newPassword,
                                        ],
                                        hintText: l10n.authPasswordPasswordHint,
                                        errorText: _passwordErrorText,
                                        obscureText: !_isPasswordVisible,
                                        showHelpTextWhenError: true,
                                        decoration: _buildAuthInputDecoration(
                                          context,
                                          suffixIcon: IconButton(
                                            onPressed: _isSubmitting
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
                                        nextDownFocus: _confirmPasswordFocusNode,
                                        onChanged: (_) {
                                          if (_passwordErrorText != null ||
                                              _globalErrorText != null) {
                                            setState(() {
                                              _passwordErrorText = null;
                                              _globalErrorText = null;
                                            });
                                          }
                                        },
                                        onFieldSubmitted: (_) {
                                          _confirmPasswordFocusNode.requestFocus();
                                        },
                                      ),
                                    ),
                                    const SizedBox(
                                      height: BootFormTokens.formElementGap,
                                    ),
                                    BootFormTokens.constrainTextField(
                                      AppLabeledTextField(
                                        label: 'Confirmez le mot de passe',
                                        controller: _confirmPasswordController,
                                        focusNode: _confirmPasswordFocusNode,
                                        enabled: !_isSubmitting,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [
                                          AutofillHints.newPassword,
                                        ],
                                        hintText: 'Confirmez le mot de passe',
                                        errorText: _confirmPasswordErrorText,
                                        obscureText: !_isConfirmPasswordVisible,
                                        showHelpTextWhenError: true,
                                        decoration: _buildAuthInputDecoration(
                                          context,
                                          suffixIcon: IconButton(
                                            onPressed: _isSubmitting
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
                                        enableFocusWrapper: true,
                                        verticalAlignment: 0.22,
                                        nextUpFocus: _passwordFocusNode,
                                        nextDownFocus: _primaryActionFocusNode,
                                        onChanged: (_) {
                                          if (_confirmPasswordErrorText != null ||
                                              _globalErrorText != null) {
                                            setState(() {
                                              _confirmPasswordErrorText = null;
                                              _globalErrorText = null;
                                            });
                                          }
                                        },
                                        onFieldSubmitted: (_) => _onSignUp(),
                                      ),
                                    ),
                                  ] else ...[
                                    BootFormTokens.constrainTextField(
                                      AppLabeledTextField(
                                        label: 'Code à 8 chiffres',
                                        controller: _codeController,
                                        focusNode: _codeFocusNode,
                                        enabled: !_isSubmitting,
                                        keyboardType: TextInputType.number,
                                        textInputAction: TextInputAction.done,
                                        maxLength: 8,
                                        counterText: '',
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                        hintText: 'Code à 8 chiffres',
                                        errorText: _codeErrorText,
                                        decoration: _buildAuthInputDecoration(
                                          context,
                                        ),
                                        enableFocusWrapper: true,
                                        verticalAlignment: 0.22,
                                        nextDownFocus: _primaryActionFocusNode,
                                        blockUp: true,
                                        onChanged: (_) {
                                          if (_codeErrorText != null ||
                                              _globalErrorText != null) {
                                            setState(() {
                                              _codeErrorText = null;
                                              _globalErrorText = null;
                                            });
                                          }
                                        },
                                        onFieldSubmitted: (_) => _onConfirmEmail(),
                                      ),
                                    ),
                                  ],
                                  if (_globalErrorText != null) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.lg,
                                      ),
                                      child: Text(
                                        _globalErrorText!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                            ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: BootFormTokens.formElementGap),
                                  MoviEnsureVisibleOnFocus(
                                    verticalAlignment: 0.22,
                                    child: Focus(
                                      canRequestFocus: false,
                                      onKeyEvent: (_, event) =>
                                          FocusDirectionalNavigation
                                              .handleDirectionalKey(
                                                event,
                                                up: _step == _SignUpStep.form
                                                    ? _confirmPasswordFocusNode
                                                    : _codeFocusNode,
                                                down: _signInFocusNode,
                                                blockLeft: true,
                                                blockRight: true,
                                              ),
                                      child: BootFormTokens.constrainPrimaryAction(
                                        MoviPrimaryButton(
                                          focusNode: _primaryActionFocusNode,
                                          label: _step == _SignUpStep.form
                                              ? 'S\'inscrire'
                                              : 'Confirmer votre email',
                                          loading: _isSubmitting,
                                          onPressed: _isSubmitting
                                              ? null
                                              : (_step == _SignUpStep.form
                                                    ? _onSignUp
                                                    : _onConfirmEmail),
                                          buttonStyle: BootFormTokens
                                              .bootPrimaryButtonStyle(
                                            Theme.of(context),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: BootFormTokens.formElementGap),
                              Text(
                                'Vous êtes déjà inscrit ?',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
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
                                      focusNode: _signInFocusNode,
                                      label: 'Se connecter',
                                      onPressed:
                                          _isSubmitting ? null : _onSignIn,
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
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _SignUpStep { form, confirmEmail }
