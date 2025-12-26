import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/core/router/app_route_names.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';
import 'package:movi/src/features/settings/presentation/providers/iptv_connect_providers.dart';
import 'package:movi/src/features/settings/presentation/providers/iptv_sources_providers.dart';
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';

class IptvSourceAddPage extends ConsumerStatefulWidget {
  const IptvSourceAddPage({super.key});

  @override
  ConsumerState<IptvSourceAddPage> createState() => _IptvSourceAddPageState();
}

class _IptvSourceAddPageState extends ConsumerState<IptvSourceAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _serverCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _macCtrl = TextEditingController();

  bool _hasSubmitted = false;
  bool _obscurePassword = true;
  final IptvSourceType _sourceType = IptvSourceType.xtream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(iptvConnectControllerProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _serverCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _macCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _hasSubmitted = true);

    final notifier = ref.read(iptvConnectControllerProvider.notifier);
    final ok = await notifier.connect(
      sourceType: _sourceType,
      serverUrl: _serverCtrl.text.trim(),
      username: _userCtrl.text.trim().isEmpty ? null : _userCtrl.text.trim(),
      password: _passCtrl.text.isEmpty ? null : _passCtrl.text,
      macAddress: _sourceType == IptvSourceType.stalker
          ? _macCtrl.text.trim()
          : null,
      alias: _nameCtrl.text.trim(),
    );

    if (!mounted) return;
    if (ok) {
      ref.invalidate(iptvAccountsProvider);
      ref.invalidate(allIptvAccountsProvider);
      ref.invalidate(stalkerAccountsProvider);
      if (!mounted) return;
      final useNow = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Utiliser cette source ?'),
            content: const Text(
              'Voulez-vous activer cette source maintenant ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Plus tard'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Utiliser'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      if (useNow == true) {
        final endpoint = XtreamEndpoint.tryParse(_serverCtrl.text.trim());
        String? accountId;
        if (endpoint != null) {
          final local = ref.read(slProvider)<IptvLocalRepository>();
          final accounts = await local.getAccounts();
          final username = _userCtrl.text.trim();
          final matches = accounts
              .where((a) => a.endpoint.host == endpoint.host && a.username == username)
              .toList();
          if (matches.isNotEmpty) {
            matches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            accountId = matches.first.id;
          } else {
            accountId = '${endpoint.host}_$username'.toLowerCase();
          }
        }
        if (accountId != null && accountId.isNotEmpty) {
          final prefs = ref.read(slProvider)<SelectedIptvSourcePreferences>();
          await prefs.setSelectedSourceId(accountId);
          ref
              .read(asp.appStateControllerProvider)
              .setActiveIptvSources({accountId});
          ref.read(appLaunchOrchestratorProvider.notifier).reset();
          if (!mounted) return;
          context.go(AppRouteNames.bootstrap);
          return;
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Source ajout?e')));
      if (!mounted) return;
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(iptvConnectControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _Header(onBack: () => context.pop()),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /*
                                  // Selecteur de type de source (masque)
                                  Text(
                                    'Type de source',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _SourceTypeButton(
                                          label: 'Xtream Codes',
                                          isSelected:
                                              _sourceType ==
                                              IptvSourceType.xtream,
                                          onTap: () => setState(
                                            () => _sourceType =
                                                IptvSourceType.xtream,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _SourceTypeButton(
                                          label: 'Stalker Portal',
                                          isSelected:
                                              _sourceType ==
                                              IptvSourceType.stalker,
                                          onTap: () => setState(
                                            () => _sourceType =
                                                IptvSourceType.stalker,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  */
                                  _FieldBlock(
                                    label: 'Nom de la source',
                                    controller: _nameCtrl,
                                    enabled: !state.isLoading,
                                    hintText: 'Mon IPTV',
                                  ),
                                  const SizedBox(height: 20),
                                  _FieldBlock(
                                    label: 'URL du serveur',
                                    controller: _serverCtrl,
                                    enabled: !state.isLoading,
                                    keyboardType: TextInputType.url,
                                    hintText:
                                        _sourceType == IptvSourceType.xtream
                                        ? 'http://server.com:80/'
                                        : 'http://server.com:80/portal.php',
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? l10n.validationRequired
                                        : null,
                                  ),
                                  const SizedBox(height: 20),
                                  _FieldBlock(
                                    label: l10n.labelUsername,
                                    controller: _userCtrl,
                                    enabled: !state.isLoading,
                                    hintText: 'Nom d\'utilisateur',
                                    autofillHints: const [
                                      AutofillHints.username,
                                    ],
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? l10n.validationRequired
                                        : null,
                                  ),
                                  const SizedBox(height: 20),
                                  _FieldBlock(
                                    label: l10n.iptvPasswordLabel,
                                    controller: _passCtrl,
                                    enabled: !state.isLoading,
                                    hintText: 'Mot de passe',
                                    obscureText: _obscurePassword,
                                    onToggleObscure: () => setState(
                                      () => _obscurePassword =
                                          !_obscurePassword,
                                    ),
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? l10n.validationRequired
                                        : null,
                                  ),

                                  const SizedBox(height: 32),
                                  SizedBox(
                                    width: double.infinity,
                                    child: MoviPrimaryButton(
                                      label: 'Ajouter la source',
                                      onPressed: state.isLoading
                                          ? null
                                          : _submit,
                                      loading: state.isLoading,
                                    ),
                                  ),
                                  if (_hasSubmitted && state.error != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      state.error!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBack,
              child: const SizedBox(
                width: 35,
                height: 35,
                child: Image(image: AssetImage(AppAssets.iconBack)),
              ),
            ),
          ),
          const Center(
            child: Text(
              'Ajouter',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({
    required this.label,
    required this.controller,
    required this.enabled,
    this.keyboardType,
    this.hintText,
    this.obscureText = false,
    this.onToggleObscure,
    this.autofillHints,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? hintText;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            obscureText: obscureText,
            autofillHints: autofillHints,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF3D3D3D),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              suffixIcon: onToggleObscure != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: IconButton(
                        icon: Icon(
                          obscureText ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white70,
                        ),
                        onPressed: onToggleObscure,
                      ),
                    )
                  : null,
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }
}

