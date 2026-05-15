import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/features/iptv/domain/entities/source_connection_models.dart';
import 'package:movi/src/features/settings/presentation/providers/iptv_network_profile_providers.dart';
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
  final _backFocusNode = FocusNode(debugLabel: 'EditSourceBack');
  final _submitFocusNode = FocusNode(debugLabel: 'EditSourceSubmit');

  bool _hasSubmitted = false;
  bool _obscurePassword = true;
  FocusNode? _editingFieldFocusNode;

  bool _didPrefillAccount = false;
  bool _didPrefillPassword = false;
  bool _didPrefillPolicy = false;
  String _preferredRouteProfileId = RouteProfile.defaultId;
  List<String> _fallbackRouteProfileIds = const <String>[];

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(_handleFieldFocusChange);
    _serverFocusNode.addListener(_handleFieldFocusChange);
    _userFocusNode.addListener(_handleFieldFocusChange);
    _passFocusNode.addListener(_handleFieldFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(iptvSourceEditControllerProvider.notifier).reset();
      _requestFocus(_nameFocusNode);
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
    _backFocusNode.dispose();
    _submitFocusNode.dispose();
    super.dispose();
  }

  void _handleFieldFocusChange() {
    final editingNode = _editingFieldFocusNode;
    if (editingNode == null || editingNode.hasFocus || !mounted) {
      return;
    }
    setState(() => _editingFieldFocusNode = null);
  }

  bool _requestFocus(FocusNode? node) {
    if (node == null || !node.canRequestFocus || node.context == null) {
      return false;
    }
    node.requestFocus();
    return true;
  }

  bool _isEditActivationKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.gameButtonA;
  }

  bool _isEditingNode(FocusNode node) {
    return identical(_editingFieldFocusNode, node);
  }

  void _startEditing(FocusNode node) {
    if (!mounted) return;
    if (!_isEditingNode(node)) {
      setState(() => _editingFieldFocusNode = node);
    }
    _requestFocus(node);
  }

  void _stopEditing() {
    if (_editingFieldFocusNode == null || !mounted) return;
    setState(() => _editingFieldFocusNode = null);
  }

  KeyEventResult _handleRouteBackKey(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.escape) {
      if (_editingFieldFocusNode != null) {
        _stopEditing();
        return KeyEventResult.handled;
      }
      if (!context.mounted) return KeyEventResult.ignored;
      context.pop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleFieldKey(
    KeyEvent event, {
    required FocusNode current,
    FocusNode? up,
    FocusNode? down,
  }) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isEditing = _isEditingNode(current);
    final key = event.logicalKey;
    if (isEditing) {
      if (key == LogicalKeyboardKey.escape ||
          key == LogicalKeyboardKey.goBack) {
        _stopEditing();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowUp) {
        _stopEditing();
        _requestFocus(up);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowDown) {
        _stopEditing();
        _requestFocus(down);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (_isEditActivationKey(key)) {
      _startEditing(current);
      return KeyEventResult.handled;
    }

    switch (key) {
      case LogicalKeyboardKey.arrowUp:
        _requestFocus(up);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _requestFocus(down);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.arrowRight:
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleBackKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      return _requestFocus(_nameFocusNode)
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleSubmitKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      return _requestFocus(_passFocusNode)
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
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

  void _prefillPolicyIfNeeded(SourceConnectionPolicy policy) {
    if (_didPrefillPolicy) return;
    _preferredRouteProfileId = policy.preferredRouteProfileId;
    _fallbackRouteProfileIds = policy.fallbackRouteProfileIds;
    _didPrefillPolicy = true;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _hasSubmitted = true);
    final routeSelection = await _normalizeRouteSelection();

    final notifier = ref.read(iptvSourceEditControllerProvider.notifier);
    final ok = await notifier.submit(
      originalAccountId: widget.accountId,
      alias: _nameCtrl.text.trim(),
      serverUrl: _serverCtrl.text.trim(),
      username: _userCtrl.text.trim(),
      password: _passCtrl.text,
      preferredRouteProfileId: routeSelection.$1,
      fallbackRouteProfileIds: routeSelection.$2,
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Source modifiée')));
      context.pop(true);
    }
  }

  Future<(String, List<String>)> _normalizeRouteSelection() async {
    final profiles = await ref.read(routeProfilesProvider.future);
    final ids = profiles.map((profile) => profile.id).toSet();
    final preferred = ids.contains(_preferredRouteProfileId)
        ? _preferredRouteProfileId
        : RouteProfile.defaultId;
    final fallbacks = _fallbackRouteProfileIds
        .where((id) => id != preferred && ids.contains(id))
        .toList(growable: false);
    if (!mounted) {
      return (preferred, fallbacks);
    }
    setState(() {
      _preferredRouteProfileId = preferred;
      _fallbackRouteProfileIds = fallbacks;
    });
    return (preferred, fallbacks);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accentColor = ref.watch(asp.currentAccentColorProvider);
    final state = ref.watch(iptvSourceEditControllerProvider);
    final accountAsync = ref.watch(iptvAccountByIdProvider(widget.accountId));
    final passwordAsync = ref.watch(
      iptvAccountPasswordProvider(widget.accountId),
    );
    final policyAsync = ref.watch(
      sourceConnectionPolicyProvider(widget.accountId),
    );
    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, event) => _handleRouteBackKey(event),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: SettingsContentWidth(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Focus(
                    canRequestFocus: false,
                    onKeyEvent: (_, event) => _handleBackKey(event),
                    child: _Header(
                      onBack: () => context.pop(),
                      focusNode: _backFocusNode,
                    ),
                  ),
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
                        policyAsync.when(
                          data: _prefillPolicyIfNeeded,
                          error: (_, __) {},
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
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
                                            readOnly:
                                                state.isLoading ||
                                                !_isEditingNode(_nameFocusNode),
                                            accentColor: accentColor,
                                            textInputAction:
                                                TextInputAction.next,
                                            onTap: () =>
                                                _startEditing(_nameFocusNode),
                                            onKeyEvent: (event) =>
                                                _handleFieldKey(
                                                  event,
                                                  current: _nameFocusNode,
                                                  up: _backFocusNode,
                                                  down: _serverFocusNode,
                                                ),
                                            onSubmitted: () =>
                                                _serverFocusNode.requestFocus(),
                                          ),
                                          const SizedBox(height: 20),
                                          _FieldBlock(
                                            label: 'URL du serveur',
                                            controller: _serverCtrl,
                                            focusNode: _serverFocusNode,
                                            enabled: !state.isLoading,
                                            readOnly:
                                                state.isLoading ||
                                                !_isEditingNode(
                                                  _serverFocusNode,
                                                ),
                                            accentColor: accentColor,
                                            keyboardType: TextInputType.url,
                                            textInputAction:
                                                TextInputAction.next,
                                            onTap: () =>
                                                _startEditing(_serverFocusNode),
                                            onKeyEvent: (event) =>
                                                _handleFieldKey(
                                                  event,
                                                  current: _serverFocusNode,
                                                  up: _nameFocusNode,
                                                  down: _userFocusNode,
                                                ),
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
                                            readOnly:
                                                state.isLoading ||
                                                !_isEditingNode(_userFocusNode),
                                            accentColor: accentColor,
                                            autofillHints: const [
                                              AutofillHints.username,
                                            ],
                                            textInputAction:
                                                TextInputAction.next,
                                            onTap: () =>
                                                _startEditing(_userFocusNode),
                                            onKeyEvent: (event) =>
                                                _handleFieldKey(
                                                  event,
                                                  current: _userFocusNode,
                                                  up: _serverFocusNode,
                                                  down: _passFocusNode,
                                                ),
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
                                            readOnly:
                                                state.isLoading ||
                                                !_isEditingNode(_passFocusNode),
                                            accentColor: accentColor,
                                            obscureText: _obscurePassword,
                                            onToggleObscure: () => setState(
                                              () => _obscurePassword =
                                                  !_obscurePassword,
                                            ),
                                            autofillHints: const [
                                              AutofillHints.password,
                                            ],
                                            textInputAction:
                                                TextInputAction.done,
                                            onTap: () =>
                                                _startEditing(_passFocusNode),
                                            onKeyEvent: (event) =>
                                                _handleFieldKey(
                                                  event,
                                                  current: _passFocusNode,
                                                  up: _userFocusNode,
                                                  down: _submitFocusNode,
                                                ),
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
                                            child: Focus(
                                              canRequestFocus: false,
                                              onKeyEvent: (_, event) =>
                                                  _handleSubmitKey(event),
                                              child: MoviPrimaryButton(
                                                label: 'Modifier la source',
                                                focusNode: _submitFocusNode,
                                                onPressed: state.isLoading
                                                    ? null
                                                    : _submit,
                                                loading: state.isLoading,
                                              ),
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
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, this.focusNode});

  final VoidCallback onBack;
  final FocusNode? focusNode;

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
                focusNode: focusNode,
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
    required this.focusNode,
    required this.readOnly,
    required this.accentColor,
    this.keyboardType,
    this.obscureText = false,
    this.onToggleObscure,
    this.autofillHints,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
    this.onTap,
    this.onKeyEvent,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final FocusNode focusNode;
  final bool readOnly;
  final Color accentColor;
  final TextInputType? keyboardType;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;
  final VoidCallback? onTap;
  final KeyEventResult Function(KeyEvent event)? onKeyEvent;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final hasFocus = focusNode.hasFocus;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: Focus(
                canRequestFocus: false,
                onKeyEvent: onKeyEvent == null
                    ? null
                    : (_, event) => onKeyEvent!(event),
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  readOnly: readOnly,
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                  autofillHints: autofillHints,
                  textInputAction: textInputAction,
                  onTap: onTap,
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
                      borderSide: BorderSide(
                        color: hasFocus ? accentColor : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(
                        color: hasFocus ? accentColor : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    suffixIcon: onToggleObscure != null
                        ? Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: IconButton(
                              icon: Icon(
                                obscureText
                                    ? Icons.visibility_off
                                    : Icons.visibility,
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
            ),
          ],
        );
      },
    );
  }
}
