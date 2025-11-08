import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/app_spacing.dart';
import '../providers/iptv_connect_providers.dart';

class IptvConnectPage extends ConsumerStatefulWidget {
  const IptvConnectPage({super.key});

  @override
  ConsumerState<IptvConnectPage> createState() => _IptvConnectPageState();
}

class _IptvConnectPageState extends ConsumerState<IptvConnectPage> {
  final _formKey = GlobalKey<FormState>();
  final _serverCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _aliasCtrl = TextEditingController();

  @override
  void dispose() {
    _serverCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _aliasCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final notifier = ref.read(iptvConnectControllerProvider.notifier);
    final ok = await notifier.connect(
      serverUrl: _serverCtrl.text.trim(),
      username: _userCtrl.text.trim(),
      password: _passCtrl.text,
      alias: _aliasCtrl.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Source IPTV ajoutée et synchronisée')),
      );
      if (context.canPop()) {
        context.pop(); // cas: ouvert depuis Settings (push)
      } else {
        context.go('/'); // cas: arrivé depuis LaunchGate (go)
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(iptvConnectControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Connexion IPTV')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Renseigne ton abonnement Xtream',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _serverCtrl,
                    decoration: const InputDecoration(
                      labelText: 'URL du serveur',
                      hintText: 'http(s)://host[:port]/player_api.php',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requis';
                      // suffisant : l’endpoint parser gèrera le reste
                      return null;
                    },
                    keyboardType: TextInputType.url,
                    autofillHints: const [AutofillHints.url],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _userCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nom d’utilisateur',
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Requis' : null,
                    autofillHints: const [AutofillHints.username],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _passCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe',
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Requis' : null,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _aliasCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Alias (facultatif)',
                      hintText: 'Ex: Mon IPTV',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.isLoading ? null : _submit,
                      child: state.isLoading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Se connecter'),
                    ),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      state.error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
