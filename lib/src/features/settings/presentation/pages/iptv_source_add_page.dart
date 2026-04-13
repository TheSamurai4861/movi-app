import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/movi_overlay_focus_scope.dart';
import 'package:movi/src/core/focus/presentation/focus_region_scope.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/core/router/app_route_names.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/core/widgets/movi_subpage_back_title_header.dart';
import 'package:movi/src/features/iptv/domain/entities/source_connection_models.dart';
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';
import 'package:movi/src/features/settings/presentation/providers/iptv_connect_providers.dart';
import 'package:movi/src/features/settings/presentation/providers/iptv_network_profile_providers.dart';
import 'package:movi/src/features/settings/presentation/providers/iptv_sources_providers.dart';
import 'package:movi/src/features/settings/presentation/widgets/settings_content_width.dart';
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
  final _nameFocusNode = FocusNode(debugLabel: 'AddSourceName');
  final _serverFocusNode = FocusNode(debugLabel: 'AddSourceServer');
  final _userFocusNode = FocusNode(debugLabel: 'AddSourceUser');
  final _passFocusNode = FocusNode(debugLabel: 'AddSourcePassword');
  final _backFocusNode = FocusNode(debugLabel: 'AddSourceBack');
  final _submitFocusNode = FocusNode(debugLabel: 'AddSourceSubmit');

  bool _hasSubmitted = false;
  bool _obscurePassword = true;
  bool _isHandlingBack = false;
  final IptvSourceType _sourceType = IptvSourceType.xtream;
  String _preferredRouteProfileId = RouteProfile.defaultId;
  List<String> _fallbackRouteProfileIds = const <String>[];

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
    _nameFocusNode.dispose();
    _serverFocusNode.dispose();
    _userFocusNode.dispose();
    _passFocusNode.dispose();
    _backFocusNode.dispose();
    _submitFocusNode.dispose();
    super.dispose();
  }

  bool _requestFocus(FocusNode node) {
    if (!node.canRequestFocus || node.context == null) {
      return false;
    }
    node.requestFocus();
    return true;
  }

  KeyEventResult _handleDirectionalKey(
    KeyEvent event, {
    FocusNode? left,
    FocusNode? right,
    FocusNode? up,
    FocusNode? down,
    bool blockLeft = true,
    bool blockRight = true,
    bool blockUp = true,
    bool blockDown = true,
  }) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    bool moveTo(FocusNode? node) => node != null && _requestFocus(node);

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        if (moveTo(left)) return KeyEventResult.handled;
        return blockLeft ? KeyEventResult.handled : KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowRight:
        if (moveTo(right)) return KeyEventResult.handled;
        return blockRight ? KeyEventResult.handled : KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowUp:
        if (moveTo(up)) return KeyEventResult.handled;
        return blockUp ? KeyEventResult.handled : KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowDown:
        if (moveTo(down)) return KeyEventResult.handled;
        return blockDown ? KeyEventResult.handled : KeyEventResult.ignored;
    }

    return KeyEventResult.ignored;
  }

  String? _determineFallbackRoute(BuildContext context) {
    if (context.canPop()) {
      return null;
    }
    return AppRouteNames.iptvSources;
  }

  bool _handleBack(BuildContext context) {
    if (!context.mounted || _isHandlingBack) {
      return false;
    }
    _isHandlingBack = true;
    final fallbackRoute = _determineFallbackRoute(context);
    if (fallbackRoute == null) {
      context.pop();
    } else {
      context.go(fallbackRoute);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _isHandlingBack = false;
      }
    });
    return true;
  }

  KeyEventResult _handleRouteBackKey(KeyEvent event, BuildContext context) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      return _handleBack(context)
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _hasSubmitted = true);
    final routeSelection = await _normalizeRouteSelection();

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
      preferredRouteProfileId: routeSelection.$1,
      fallbackRouteProfileIds: routeSelection.$2,
    );

    if (!mounted) return;
    if (ok) {
      ref.invalidate(iptvAccountsProvider);
      ref.invalidate(allIptvAccountsProvider);
      ref.invalidate(stalkerAccountsProvider);
      if (!mounted) return;
      final useNow = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return _UseSourceNowDialog(triggerFocusNode: _submitFocusNode);
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
              .where(
                (a) =>
                    a.endpoint.host == endpoint.host && a.username == username,
              )
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
          ref.read(asp.appStateControllerProvider).setActiveIptvSources({
            accountId,
          });
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
    final state = ref.watch(iptvConnectControllerProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: FocusRegionScope(
        regionId: AppFocusRegionId.settingsIptvSourceAddPrimary,
        binding: FocusRegionBinding(
          resolvePrimaryEntryNode: () => _nameFocusNode,
          resolveFallbackEntryNode: () => _backFocusNode,
        ),
        requestFocusOnMount: true,
        handleDirectionalExits: false,
        debugLabel: 'IptvSourceAddRegion',
        child: Focus(
          canRequestFocus: false,
          onKeyEvent: (_, event) => _handleRouteBackKey(event, context),
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
                      onKeyEvent: (_, event) => _handleDirectionalKey(
                        event,
                        down: _nameFocusNode,
                        blockUp: true,
                      ),
                      child: MoviSubpageBackTitleHeader(
                        title: 'Ajouter',
                        focusNode: _backFocusNode,
                        onBack: () => _handleBack(context),
                      ),
                    ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                        IptvSourceAddFieldBlock(
                                          label: 'Nom de la source',
                                          controller: _nameCtrl,
                                          focusNode: _nameFocusNode,
                                          enabled: !state.isLoading,
                                          hintText: 'Mon IPTV',
                                          textInputAction: TextInputAction.next,
                                          onKeyEvent: (event) =>
                                              _handleDirectionalKey(
                                                event,
                                                up: _backFocusNode,
                                                down: _serverFocusNode,
                                              ),
                                          onSubmitted: () =>
                                              _serverFocusNode.requestFocus(),
                                        ),
                                        const SizedBox(height: 20),
                                        IptvSourceAddFieldBlock(
                                          label: 'URL du serveur',
                                          controller: _serverCtrl,
                                          focusNode: _serverFocusNode,
                                          enabled: !state.isLoading,
                                          keyboardType: TextInputType.url,
                                          hintText:
                                              _sourceType ==
                                                  IptvSourceType.xtream
                                              ? 'http://server.com:80/'
                                              : 'http://server.com:80/portal.php',
                                          textInputAction: TextInputAction.next,
                                          onKeyEvent: (event) =>
                                              _handleDirectionalKey(
                                                event,
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
                                        IptvSourceAddFieldBlock(
                                          label: l10n.labelUsername,
                                          controller: _userCtrl,
                                          focusNode: _userFocusNode,
                                          enabled: !state.isLoading,
                                          hintText: 'Nom d\'utilisateur',
                                          autofillHints: const [
                                            AutofillHints.username,
                                          ],
                                          textInputAction: TextInputAction.next,
                                          onKeyEvent: (event) =>
                                              _handleDirectionalKey(
                                                event,
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
                                        IptvSourceAddFieldBlock(
                                          label: l10n.iptvPasswordLabel,
                                          controller: _passCtrl,
                                          focusNode: _passFocusNode,
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
                                          textInputAction: TextInputAction.done,
                                          onKeyEvent: (event) =>
                                              _handleDirectionalKey(
                                                event,
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
                                                _handleDirectionalKey(
                                                  event,
                                                  up: _passFocusNode,
                                                  blockDown: true,
                                                  blockLeft: true,
                                                  blockRight: true,
                                                ),
                                            child: MoviPrimaryButton(
                                              label: 'Ajouter la source',
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
    );
  }
}

class IptvSourceAddFieldBlock extends StatelessWidget {
  const IptvSourceAddFieldBlock({
    super.key,
    required this.label,
    required this.controller,
    required this.enabled,
    this.focusNode,
    this.keyboardType,
    this.hintText,
    this.obscureText = false,
    this.onToggleObscure,
    this.autofillHints,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
    this.onKeyEvent,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final String? hintText;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;
  final KeyEventResult Function(KeyEvent event)? onKeyEvent;

  @override
  Widget build(BuildContext context) {
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
              keyboardType: keyboardType,
              obscureText: obscureText,
              autofillHints: autofillHints,
              textInputAction: textInputAction,
              onFieldSubmitted: (_) => onSubmitted?.call(),
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
  }
}

class _UseSourceNowDialog extends StatefulWidget {
  const _UseSourceNowDialog({this.triggerFocusNode});

  final FocusNode? triggerFocusNode;

  @override
  State<_UseSourceNowDialog> createState() => _UseSourceNowDialogState();
}

class _UseSourceNowDialogState extends State<_UseSourceNowDialog> {
  late final FocusNode _laterFocusNode = FocusNode(
    debugLabel: 'AddSourceUseNowLater',
  );
  late final FocusNode _useFocusNode = FocusNode(
    debugLabel: 'AddSourceUseNowUse',
  );

  @override
  void dispose() {
    _laterFocusNode.dispose();
    _useFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MoviOverlayFocusScope(
      triggerFocusNode: widget.triggerFocusNode,
      initialFocusNode: _useFocusNode,
      fallbackFocusNode: _laterFocusNode,
      originRegionId: AppFocusRegionId.settingsIptvSourceAddPrimary,
      fallbackRegionId: AppFocusRegionId.settingsIptvSourceAddPrimary,
      debugLabel: 'IptvSourceAddUseNowDialog',
      child: AlertDialog(
        title: const Text('Utiliser cette source ?'),
        content: const Text('Voulez-vous activer cette source maintenant ?'),
        actions: [
          TextButton(
            focusNode: _laterFocusNode,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Plus tard'),
          ),
          FilledButton(
            focusNode: _useFocusNode,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Utiliser'),
          ),
        ],
      ),
    );
  }
}
