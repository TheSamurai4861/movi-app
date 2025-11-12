import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../../welcome/presentation/widgets/labeled_field.dart';
import '../../../welcome/presentation/widgets/welcome_header.dart';
import '../../../../core/widgets/movi_primary_button.dart';
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
                  const WelcomeHeader(
                    title: 'Bienvenue !',
                    subtitle: 'Ajoute une source IPTV pour personnaliser Movi.',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LabeledField(
                          label: 'URL du serveur Xtream',
                          child: TextFormField(
                            controller: _serverCtrl,
                            decoration: const InputDecoration(
                              hintText: 'http(s)://host[:port]/player_api.php',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Requis';
                              return null;
                            },
                            keyboardType: TextInputType.url,
                            autofillHints: const [AutofillHints.url],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        LabeledField(
                          label: 'Nom d’utilisateur Xtream',
                          child: TextFormField(
                            controller: _userCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Nom d’utilisateur Xtream',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                            autofillHints: const [AutofillHints.username],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        LabeledField(
                          label: 'Mot de passe Xtream',
                          child: TextFormField(
                            controller: _passCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Mot de passe Xtream',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                            obscureText: true,
                            autofillHints: const [AutofillHints.password],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        LabeledField(
                          label: 'Alias (facultatif)',
                          child: TextFormField(
                            controller: _aliasCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Ex: Mon IPTV',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: SizedBox(
                            width: double.infinity,
                            child: MoviPrimaryButton(
                              label: 'Se connecter',
                              onPressed: state.isLoading ? null : _submit,
                              loading: state.isLoading,
                            ),
                          ),
                        ),
                        if (state.error != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(state.error!, style: const TextStyle(color: Colors.red)),
                        ],
                      ],
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
}
