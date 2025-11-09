import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/utils/app_spacing.dart';

import '../providers/welcome_providers.dart';
import '../../../../core/iptv/domain/value_objects/xtream_endpoint.dart';
import '../../../settings/presentation/providers/iptv_connect_providers.dart';

class WelcomeForm extends ConsumerStatefulWidget {
  const WelcomeForm({super.key});

  @override
  ConsumerState<WelcomeForm> createState() => _WelcomeFormState();
}

class _WelcomeFormState extends ConsumerState<WelcomeForm> {
  final _formKey = GlobalKey<FormState>();

  final _urlCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _aliasCtrl = TextEditingController();

  final _focusUrl = FocusNode();
  final _focusUser = FocusNode();
  final _focusPass = FocusNode();
  final _focusAlias = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusUrl.requestFocus();
    _urlCtrl.addListener(() {
      ref
          .read(welcomeControllerProvider.notifier)
          .updateUrlPreview(_urlCtrl.text);
    });
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _aliasCtrl.dispose();
    _focusUrl.dispose();
    _focusUser.dispose();
    _focusPass.dispose();
    _focusAlias.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    final ep = XtreamEndpoint.tryParse(_urlCtrl.text);
    return ep != null &&
        _userCtrl.text.trim().isNotEmpty &&
        _passCtrl.text.isNotEmpty;
  }

  Future<void> _onTest() async {
    final ui = ref.read(welcomeControllerProvider.notifier);
    final ok = await ui.testConnection(
      serverUrl: _urlCtrl.text.trim(),
      username: _userCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (!mounted) return;
    final state = ref.read(welcomeControllerProvider);
    final msg = ok
        ? 'Connexion réussie ✅'
        : presentFailureMessage(state.errorMessage);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ctrl = ref.read(iptvConnectControllerProvider.notifier);
    final ok = await ctrl.connect(
      serverUrl: _urlCtrl.text.trim(),
      username: _userCtrl.text.trim(),
      password: _passCtrl.text,
      alias: _aliasCtrl.text.trim(),
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Source IPTV ajoutée et synchronisée')),
      );
      Navigator.of(context).popUntil((r) => r.isFirst);
    } else {
      final err =
          ref.read(iptvConnectControllerProvider).error ?? 'Échec de connexion';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  String presentFailureMessage(String? raw) {
    if (raw == null || raw.isEmpty) return 'Échec de connexion';
    // Raw vient du Failure.message ; tu peux affiner via presentFailure si tu stockes le Failure au lieu de son message.
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(welcomeControllerProvider);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          // URL
          _LabeledField(
            label: 'URL du serveur',
            footer: ui.endpointPreview != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Endpoint détecté : ${ui.endpointPreview}',
                      style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant),
                    ),
                  )
                : null,
            child: TextFormField(
              controller: _urlCtrl,
              focusNode: _focusUrl,
              autofillHints: const [AutofillHints.url],
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _focusUser.requestFocus(),
              decoration: const InputDecoration(
                hintText: 'http(s)://host[:port]/player_api.php',
              ),
              validator: (v) => (XtreamEndpoint.tryParse(v ?? '') == null)
                  ? 'URL invalide'
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Username
          _LabeledField(
            label: 'Nom d’utilisateur',
            child: TextFormField(
              controller: _userCtrl,
              focusNode: _focusUser,
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _focusPass.requestFocus(),
              decoration: const InputDecoration(hintText: 'Identifiant Xtream'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Password
          _LabeledField(
            label: 'Mot de passe',
            child: TextFormField(
              controller: _passCtrl,
              focusNode: _focusPass,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _focusAlias.requestFocus(),
              decoration: InputDecoration(
                hintText: 'Mot de passe Xtream',
                suffixIcon: IconButton(
                  onPressed: () => ref
                      .read(welcomeControllerProvider.notifier)
                      .toggleObscure(),
                  icon: Icon(
                    ui.isObscured ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
              obscureText: ui.isObscured,
              validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Alias (optionnel)
          _LabeledField(
            label: 'Nom de la source (Optionnel)',
            child: TextFormField(
              controller: _aliasCtrl,
              focusNode: _focusAlias,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (_isFormValid) _onSubmit();
              },
              decoration: const InputDecoration(
                hintText: 'Nom d’affichage dans l’app',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Nouveau bloc d’action unique ✅
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isFormValid ? _onSubmit : null,
                child: const Text('Ajouter la source'),
              ),
            ),
          ),

          if (ui.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                presentFailureMessage(ui.errorMessage),
                style: t.bodyMedium?.copyWith(color: Colors.redAccent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child, this.footer});

  final String label;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          child,
          if (footer != null) footer!,
        ],
      ),
    );
  }
}
