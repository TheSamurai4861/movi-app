import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/features/settings/presentation/providers/iptv_source_edit_providers.dart';
import 'package:movi/src/features/settings/presentation/widgets/settings_content_width.dart';

class IptvSourceEditPage extends ConsumerStatefulWidget {
  const IptvSourceEditPage({super.key, required this.accountId});

  final String accountId;

  @override
  ConsumerState<IptvSourceEditPage> createState() => _IptvSourceEditPageState();
}

class _IptvSourceEditPageState extends ConsumerState<IptvSourceEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _serverCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameFocusNode = FocusNode(debugLabel: 'EditSourceName');
  final _serverFocusNode = FocusNode(debugLabel: 'EditSourceServer');
  final _userFocusNode = FocusNode(debugLabel: 'EditSourceUser');
  final _passFocusNode = FocusNode(debugLabel: 'EditSourcePassword');
  final _submitFocusNode = FocusNode(debugLabel: 'EditSourceSubmit');

  bool _hasSubmitted = false;
  bool _obscurePassword = true;

  bool _didPrefillAccount = false;
  bool _didPrefillPassword = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(iptvSourceEditControllerProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _serverCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _nameFocusNode.dispose();
    _serverFocusNode.dispose();
    _userFocusNode.dispose();
    _passFocusNode.dispose();
    _submitFocusNode.dispose();
    super.dispose();
  }

  void _prefillAccountIfNeeded({
    required String alias,
    required String serverUrl,
    required String username,
  }) {
    if (_didPrefillAccount) return;
    _nameCtrl.text = alias;
    _serverCtrl.text = serverUrl;
    _userCtrl.text = username;
    _didPrefillAccount = true;
  }

  void _prefillPasswordIfNeeded(String? password) {
    if (_didPrefillPassword) return;
    if (password != null && password.isNotEmpty && _passCtrl.text.isEmpty) {
      _passCtrl.text = password;
    }
    _didPrefillPassword = true;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _hasSubmitted = true);

    final notifier = ref.read(iptvSourceEditControllerProvider.notifier);
    final ok = await notifier.submit(
      originalAccountId: widget.accountId,
      alias: _nameCtrl.text.trim(),
      serverUrl: _serverCtrl.text.trim(),
      username: _userCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Source modifiée')));
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(iptvSourceEditControllerProvider);
    final accountAsync = ref.watch(iptvAccountByIdProvider(widget.accountId));
    final passwordAsync = ref.watch(
      iptvAccountPasswordProvider(widget.accountId),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SettingsContentWidth(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _Header(onBack: () => context.pop()),
                Expanded(
                  child: accountAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text(
                        e.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    data: (account) {
                      if (account == null) {
                        return Center(
                          child: Text(
                            l10n.notFoundWithEntity(l10n.entitySource),
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }

                      _prefillAccountIfNeeded(
                        alias: account.alias,
                        serverUrl: account.endpoint.toRawUrl(),
                        username: account.username,
                      );

                      passwordAsync.when(
                        data: _prefillPasswordIfNeeded,
                        error: (_, __) => _prefillPasswordIfNeeded(null),
                        loading: () {},
                      );

                      return LayoutBuilder(
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _FieldBlock(
                                          label: 'Nom de la source',
                                          controller: _nameCtrl,
                                          focusNode: _nameFocusNode,
                                          enabled: !state.isLoading,
                                          textInputAction: TextInputAction.next,
                                          onSubmitted: () =>
                                              _serverFocusNode.requestFocus(),
                                        ),
                                        const SizedBox(height: 20),
                                        _FieldBlock(
                                          label: 'URL du serveur',
                                          controller: _serverCtrl,
                                          focusNode: _serverFocusNode,
                                          enabled: !state.isLoading,
                                          keyboardType: TextInputType.url,
                                          textInputAction: TextInputAction.next,
                                          onSubmitted: () =>
                                              _userFocusNode.requestFocus(),
                                          validator: (v) =>
                                              (v == null || v.trim().isEmpty)
                                              ? l10n.validationRequired
                                              : null,
                                        ),
                                        const SizedBox(height: 20),
                                        _FieldBlock(
                                          label: l10n.labelUsername,
                                          controller: _userCtrl,
                                          focusNode: _userFocusNode,
                                          enabled: !state.isLoading,
                                          autofillHints: const [
                                            AutofillHints.username,
                                          ],
                                          textInputAction: TextInputAction.next,
                                          onSubmitted: () =>
                                              _passFocusNode.requestFocus(),
                                          validator: (v) =>
                                              (v == null || v.trim().isEmpty)
                                              ? l10n.validationRequired
                                              : null,
                                        ),
                                        const SizedBox(height: 20),
                                        _FieldBlock(
                                          label: l10n.iptvPasswordLabel,
                                          controller: _passCtrl,
                                          focusNode: _passFocusNode,
                                          enabled: !state.isLoading,
                                          obscureText: _obscurePassword,
                                          onToggleObscure: () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
                                          autofillHints: const [
                                            AutofillHints.password,
                                          ],
                                          textInputAction: TextInputAction.done,
                                          onSubmitted: () =>
                                              _submitFocusNode.requestFocus(),
                                          validator: (v) =>
                                              (v == null || v.isEmpty)
                                              ? l10n.validationRequired
                                              : null,
                                        ),
                                        const SizedBox(height: 32),
                                        SizedBox(
                                          width: double.infinity,
                                          child: MoviPrimaryButton(
                                            label: 'Modifier la source',
                                            focusNode: _submitFocusNode,
                                            onPressed: state.isLoading
                                                ? null
                                                : _submit,
                                            loading: state.isLoading,
                                          ),
                                        ),
                                        if (_hasSubmitted &&
                                            state.error != null) ...[
                                          const SizedBox(height: 12),
                                          Text(
                                            state.error!,
                                            style: const TextStyle(
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
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
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
            child: SizedBox(
              width: 35,
              height: 35,
              child: MoviFocusableAction(
                onPressed: onBack,
                semanticLabel: 'Retour',
                builder: (context, state) {
                  return MoviFocusFrame(
                    scale: state.focused ? 1.04 : 1,
                    borderRadius: BorderRadius.circular(999),
                    backgroundColor: state.focused
                        ? Colors.white.withValues(alpha: 0.14)
                        : Colors.transparent,
                    child: const SizedBox(
                      width: 35,
                      height: 35,
                      child: MoviAssetIcon(
                        AppAssets.iconBack,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const Center(
            child: Text(
              'Modifier',
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
    this.focusNode,
    this.keyboardType,
    this.obscureText = false,
    this.onToggleObscure,
    this.autofillHints,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;

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
            focusNode: focusNode,
            enabled: enabled,
            keyboardType: keyboardType,
            obscureText: obscureText,
            autofillHints: autofillHints,
            textInputAction: textInputAction,
            onFieldSubmitted: (_) => onSubmitted?.call(),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
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
