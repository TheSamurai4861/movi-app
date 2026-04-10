import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/features/iptv/domain/entities/source_connection_models.dart';
import 'package:movi/src/features/settings/presentation/providers/iptv_network_profile_providers.dart';
import 'package:movi/src/features/settings/presentation/widgets/settings_content_width.dart';

class IptvNetworkProfilesPage extends ConsumerWidget {
  const IptvNetworkProfilesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(routeProfilesProvider);
    final state = ref.watch(networkProfileEditControllerProvider);
    final controller = ref.read(networkProfileEditControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SettingsContentWidth(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(onBack: () => context.pop()),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Profils reseau Xtream',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: state.isLoading
                          ? null
                          : () => _showProfileDialog(context, ref),
                      child: const Text('Ajouter'),
                    ),
                  ],
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
                const SizedBox(height: 20),
                Expanded(
                  child: profilesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: Text(
                        error.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    data: (profiles) => ListView.separated(
                      itemCount: profiles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final profile = profiles[index];
                        return _RouteProfileCard(
                          profile: profile,
                          busy: state.isLoading,
                          onEdit: profile.isDefault
                              ? null
                              : () => _showProfileDialog(
                                    context,
                                    ref,
                                    profile: profile,
                                  ),
                          onDelete: profile.isDefault
                              ? null
                              : () => controller.deleteProfile(profile.id),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showProfileDialog(
    BuildContext context,
    WidgetRef ref, {
    RouteProfile? profile,
  }) async {
    final creds = profile == null
        ? null
        : await ref.read(routeProfileCredentialsStoreProvider).read(profile.id);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return _RouteProfileDialog(
          profile: profile,
          credentials: creds,
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        const SizedBox(width: 8),
        const Text(
          'Profils reseau',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RouteProfileCard extends StatelessWidget {
  const _RouteProfileCard({
    required this.profile,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  final RouteProfile profile;
  final bool busy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitle = profile.kind == RouteProfileKind.defaultRoute
        ? 'Route systeme'
        : '${profile.proxyScheme ?? 'http'}://${profile.proxyHost ?? '-'}:${profile.proxyPort ?? '-'}';
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF404040)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  profile.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: profile.enabled
                      ? const Color(0xFF2160AB)
                      : Colors.white12,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  profile.enabled ? 'Actif' : 'Desactive',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: busy ? null : onEdit,
                child: const Text('Modifier'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: busy ? null : onDelete,
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteProfileDialog extends ConsumerStatefulWidget {
  const _RouteProfileDialog({
    this.profile,
    this.credentials,
  });

  final RouteProfile? profile;
  final RouteProfileCredentials? credentials;

  @override
  ConsumerState<_RouteProfileDialog> createState() => _RouteProfileDialogState();
}

class _RouteProfileDialogState extends ConsumerState<_RouteProfileDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _hostCtrl;
  late final TextEditingController _portCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _passCtrl;
  late String _scheme;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _nameCtrl = TextEditingController(text: profile?.name ?? '');
    _hostCtrl = TextEditingController(text: profile?.proxyHost ?? '');
    _portCtrl = TextEditingController(
      text: profile?.proxyPort?.toString() ?? '8080',
    );
    _userCtrl = TextEditingController(text: widget.credentials?.username ?? '');
    _passCtrl = TextEditingController(text: widget.credentials?.password ?? '');
    _scheme = profile?.proxyScheme ?? 'http';
    _enabled = profile?.enabled ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(networkProfileEditControllerProvider);
    return AlertDialog(
      backgroundColor: const Color(0xFF1D1D1D),
      title: Text(
        widget.profile == null ? 'Ajouter un proxy' : 'Modifier le proxy',
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Field(controller: _nameCtrl, label: 'Nom'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(_scheme),
                initialValue: _scheme,
                decoration: _decoration('Scheme'),
                dropdownColor: const Color(0xFF262626),
                items: const [
                  DropdownMenuItem(value: 'http', child: Text('http')),
                  DropdownMenuItem(value: 'https', child: Text('https')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _scheme = value);
                },
              ),
              const SizedBox(height: 12),
              _Field(controller: _hostCtrl, label: 'Host proxy'),
              const SizedBox(height: 12),
              _Field(
                controller: _portCtrl,
                label: 'Port proxy',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _Field(controller: _userCtrl, label: 'Username proxy (optionnel)'),
              const SizedBox(height: 12),
              _Field(
                controller: _passCtrl,
                label: 'Password proxy (optionnel)',
                obscureText: true,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
                title: const Text(
                  'Activer ce profil',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              if (state.error != null)
                Text(
                  state.error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: state.isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: state.isLoading ? null : _save,
          child: state.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final port = int.tryParse(_portCtrl.text.trim());
    if (_nameCtrl.text.trim().isEmpty ||
        _hostCtrl.text.trim().isEmpty ||
        port == null ||
        port <= 0) {
      return;
    }
    final saved = await ref
        .read(networkProfileEditControllerProvider.notifier)
        .saveProxyProfile(
          id: widget.profile?.id,
          name: _nameCtrl.text.trim(),
          scheme: _scheme,
          host: _hostCtrl.text.trim(),
          port: port,
          enabled: _enabled,
          proxyUsername: _userCtrl.text.trim(),
          proxyPassword: _passCtrl.text,
        );
    if (!mounted || saved == null) return;
    Navigator.of(context).pop();
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF2B2B2B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF2B2B2B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
      ),
    );
  }
}
