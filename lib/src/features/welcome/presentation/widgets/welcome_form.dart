// lib/src/features/welcome/presentation/widgets/welcome_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/features/welcome/presentation/widgets/labeled_field.dart';

import 'package:movi/src/features/welcome/presentation/providers/welcome_providers.dart';
import 'package:movi/src/features/iptv/iptv.dart';
import 'package:movi/src/features/settings/presentation/providers/iptv_connect_providers.dart';

typedef ConnectCallback =
    Future<void> Function(String serverUrl, String username, String password);

class WelcomeForm extends ConsumerStatefulWidget {
  const WelcomeForm({
    super.key,
    this.onConnect, // <- ajouté pour correspondre à WelcomePage
    this.isLoading, // <- ajouté pour correspondre à WelcomePage
  });

  /// Si fourni, c’est le parent (WelcomePage) qui gère la connexion + navigation.
  final ConnectCallback? onConnect;

  /// Si fourni, force l’état de chargement (sinon on lit le provider interne).
  final bool? isLoading;

  @override
  ConsumerState<WelcomeForm> createState() => _WelcomeFormState();
}

class _WelcomeFormState extends ConsumerState<WelcomeForm> {
  final _formKey = GlobalKey<FormState>();

  final _urlCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  final _focusUrl = FocusNode();
  final _focusUser = FocusNode();
  final _focusPass = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusUrl.requestFocus();

    // URL: conserve l’aperçu + force le rebuild pour le bouton
    _urlCtrl.addListener(() {
      ref
          .read(welcomeControllerProvider.notifier)
          .updateUrlPreview(_urlCtrl.text);
      _recompute();
    });

    // NEW: force le rebuild quand user/password changent
    _userCtrl.addListener(_recompute);
    _passCtrl.addListener(_recompute);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _focusUrl.dispose();
    _focusUser.dispose();
    _focusPass.dispose();
    super.dispose();
  }

  void _recompute() {
    if (mounted) setState(() {});
  }

  bool get _isFormValid {
    final ep = XtreamEndpoint.tryParse(_urlCtrl.text);
    return ep != null &&
        _userCtrl.text.trim().isNotEmpty &&
        _passCtrl.text.isNotEmpty;
  }

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Si le parent fournit onConnect, on délègue (il gère la nav et le snackBar).
    if (widget.onConnect != null) {
      await widget.onConnect!(
        _urlCtrl.text.trim(),
        _userCtrl.text.trim(),
        _passCtrl.text,
      );
      return;
    }

    // Sinon, on utilise le provider interne + nav directe.
    final ctrl = ref.read(iptvConnectControllerProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final l10n = AppLocalizations.of(context)!;
    final ok = await ctrl.connect(
      sourceType: IptvSourceType.xtream,
      serverUrl: _urlCtrl.text.trim(),
      username: _userCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (ok) {
      // ✅ Nav immédiate — la synchro tourne en arrière-plan (voir iptv_connect_providers)
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.snackbarSourceAddedBackground)),
      );
      router.go(AppRouteNames.home);
    } else {
      final err = ref.read(iptvConnectControllerProvider).error;
      final msg = err == null || err.isEmpty
          ? l10n.errorConnectionGeneric
          : l10n.errorConnectionFailed(err);
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(welcomeControllerProvider);
    final connectState = ref.watch(iptvConnectControllerProvider);
    // isLoading effectif : priorité au paramètre venant du parent (WelcomePage)
    final isLoading = widget.isLoading ?? connectState.isLoading;

    final t = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          // URL
          LabeledField(
            label: AppLocalizations.of(context)!.iptvServerUrlLabel,
            child: TextFormField(
              controller: _urlCtrl,
              focusNode: _focusUrl,
              readOnly: isLoading,
              autofillHints: const [AutofillHints.url],
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _focusUser.requestFocus(),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.iptvServerUrlHint,
              ),
              validator: (v) => (XtreamEndpoint.tryParse(v ?? '') == null)
                  ? AppLocalizations.of(context)!.validationInvalidUrl
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Username
          LabeledField(
            label: AppLocalizations.of(context)!.iptvUsernameLabel,
            child: TextFormField(
              controller: _userCtrl,
              focusNode: _focusUser,
              readOnly: isLoading,
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _focusPass.requestFocus(),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.iptvUsernameHint,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? AppLocalizations.of(context)!.validationRequired
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Password
          LabeledField(
            label: AppLocalizations.of(context)!.iptvPasswordLabel,
            child: TextFormField(
              controller: _passCtrl,
              focusNode: _focusPass,
              readOnly: isLoading,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (_isFormValid && !isLoading) _onSubmit();
              },
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.iptvPasswordHint,
                suffixIcon: IconButton(
                  onPressed: isLoading
                      ? null
                      : () => ref
                            .read(welcomeControllerProvider.notifier)
                            .toggleObscure(),
                  icon: Icon(
                    ui.isObscured ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
              obscureText: ui.isObscured,
              validator: (v) => (v == null || v.isEmpty)
                  ? AppLocalizations.of(context)!.validationRequired
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const SizedBox(height: AppSpacing.xl),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: MoviPrimaryButton(
                label: AppLocalizations.of(context)!.welcomeSourceAdd,
                onPressed: (!isLoading && _isFormValid) ? _onSubmit : null,
                loading: isLoading,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: (!isLoading && _isFormValid && !ui.isTesting)
                    ? () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final l10n = AppLocalizations.of(context)!;
                        final ok = await ref
                            .read(welcomeControllerProvider.notifier)
                            .testConnection(
                              context: context,
                              serverUrl: _urlCtrl.text.trim(),
                              username: _userCtrl.text.trim(),
                              password: _passCtrl.text,
                            );
                        if (!ok) {
                          final ui = ref.read(welcomeControllerProvider);
                          final error =
                              ui.errorMessage ?? l10n.errorConnectionGeneric;
                          messenger.showSnackBar(
                            SnackBar(content: Text(error)),
                          );
                        }
                      }
                    : null,
                child: ui.isTesting
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AppLocalizations.of(context)!.actionConnect),
              ),
            ),
          ),

          if (ui.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                ui.errorMessage!,
                style: t.bodyMedium?.copyWith(color: Colors.redAccent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
