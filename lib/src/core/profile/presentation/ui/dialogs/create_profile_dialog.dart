import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/movi_overlay_focus_scope.dart';
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/presentation/providers/profiles_providers.dart';
import 'package:movi/src/core/profile/presentation/ui/dialogs/profile_dialog_focus_border.dart';
import 'package:movi/src/core/profile/presentation/ui/dialogs/restart_required_dialog.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/core/widgets/modal_content_width.dart';

/// Modal dialog pour créer un nouveau profil.
class CreateProfileDialog extends ConsumerStatefulWidget {
  const CreateProfileDialog({super.key, this.triggerFocusNode});

  final FocusNode? triggerFocusNode;

  /// Affiche la modal et retourne true si un profil a été créé.
  static Future<bool> show(
    BuildContext context, {
    FocusNode? triggerFocusNode,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) =>
          CreateProfileDialog(triggerFocusNode: triggerFocusNode),
    );
    return result ?? false;
  }

  @override
  ConsumerState<CreateProfileDialog> createState() =>
      _CreateProfileDialogState();
}

class _CreateProfileDialogState extends ConsumerState<CreateProfileDialog> {
  final _nameController = TextEditingController();

  late final FocusNode _nameFocusNode;
  late final FocusNode _kidSwitchFocusNode;
  late final FocusNode _firstPegiFocusNode;
  late final List<FocusNode> _pegiFocusNodes;
  late final FocusNode _pinButtonFocusNode;
  late final FocusNode _cancelButtonFocusNode;
  late final FocusNode _confirmButtonFocusNode;

  bool _isLoading = false;
  String? _error;
  bool _isKid = false;
  int _pegiLimit = 12;
  String? _pin;
  String? _pinConfirmationMessage;

  @override
  void initState() {
    super.initState();
    _nameFocusNode = FocusNode(debugLabel: 'CreateProfileName');
    _kidSwitchFocusNode = FocusNode(debugLabel: 'CreateProfileKidSwitch');
    _firstPegiFocusNode = FocusNode(debugLabel: 'CreateProfileFirstPegi');
    _pegiFocusNodes = List<FocusNode>.generate(
      5,
      (index) => index == 0
          ? _firstPegiFocusNode
          : FocusNode(debugLabel: 'CreateProfilePegi$index'),
    );
    _pinButtonFocusNode = FocusNode(debugLabel: 'CreateProfilePin');
    _cancelButtonFocusNode = FocusNode(debugLabel: 'CreateProfileCancel');
    _confirmButtonFocusNode = FocusNode(debugLabel: 'CreateProfileConfirm');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _kidSwitchFocusNode.dispose();
    for (final node in _pegiFocusNodes) {
      if (!identical(node, _firstPegiFocusNode)) {
        node.dispose();
      }
    }
    _firstPegiFocusNode.dispose();
    _pinButtonFocusNode.dispose();
    _cancelButtonFocusNode.dispose();
    _confirmButtonFocusNode.dispose();
    super.dispose();
  }

  bool _useDesktopTvLayout(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenType = ScreenTypeResolver.instance.resolve(
      size.width,
      size.height,
    );
    return screenType == ScreenType.desktop || screenType == ScreenType.tv;
  }

  bool _requestFocus(FocusNode node) {
    if (!node.canRequestFocus || node.context == null) {
      return false;
    }
    node.requestFocus();
    return true;
  }

  FocusNode _primaryBottomActionTarget(bool canCreate) {
    return canCreate ? _confirmButtonFocusNode : _cancelButtonFocusNode;
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

  KeyEventResult _handleDialogBackKey(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (_isLoading) {
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop(false);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  ButtonStyle _destructiveCancelButtonStyle() {
    return OutlinedButton.styleFrom(
      side: const BorderSide(color: Colors.red),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
    );
  }

  Future<void> _createProfile() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = l10n.errorFillFields);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final color = accentColor.toARGB32();

    final Profile? created = await ref
        .read(profilesControllerProvider.notifier)
        .createProfile(name: name, color: color);

    if (!mounted) return;

    if (created == null) {
      setState(() {
        _isLoading = false;
        _error = l10n.errorUnknown;
      });
      return;
    }

    if (_isKid) {
      final pin = _pin?.trim();
      if (pin != null &&
          pin.isNotEmpty &&
          !RegExp(r'^\d{4,6}$').hasMatch(pin)) {
        setState(() {
          _isLoading = false;
          _error = 'PIN invalide (4-6 chiffres)';
        });
        return;
      }

      try {
        final ok = await ref
            .read(profilesControllerProvider.notifier)
            .updateProfile(
              profileId: created.id,
              isKid: true,
              pegiLimit: _pegiLimit,
            );

        if (!ok) {
          await ref
              .read(profilesControllerProvider.notifier)
              .deleteProfile(created.id);
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _error = 'Impossible d\'appliquer le contrôle parental';
          });
          return;
        }

        if (pin != null && RegExp(r'^\d{4,6}$').hasMatch(pin)) {
          final pinSvc = ref.read(parental.profilePinEdgeServiceProvider);
          await pinSvc.setPin(profileId: created.id, pin: pin);
        }

        await ref.read(profilesControllerProvider.notifier).refresh();
      } catch (e) {
        await ref
            .read(profilesControllerProvider.notifier)
            .deleteProfile(created.id);
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'Erreur PIN: $e';
        });
        return;
      }

      if (!mounted) return;
      final shouldRestart = await RestartRequiredDialog.show(context);
      if (shouldRestart) {
        return;
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final useDesktopTvLayout = _useDesktopTvLayout(context);

    final bool canCreate =
        !_isLoading && _nameController.text.trim().isNotEmpty;
    final bottomActionTarget = _primaryBottomActionTarget(canCreate);

    final dialog = Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ModalContentWidth(
        maxWidth: 560,
        maxHeight: MediaQuery.of(context).size.height * 0.9,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Focus(
            canRequestFocus: false,
            onKeyEvent: (_, event) => useDesktopTvLayout
                ? _handleDialogBackKey(event)
                : KeyEventResult.ignored,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.settingsProfileInfoTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!useDesktopTvLayout)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white60),
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(false),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pseudo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Focus(
                      canRequestFocus: false,
                      onKeyEvent: (_, event) => useDesktopTvLayout
                          ? _handleDirectionalKey(
                              event,
                              down: _kidSwitchFocusNode,
                              blockUp: true,
                              blockLeft: false,
                              blockRight: false,
                            )
                          : KeyEventResult.ignored,
                      child: CallbackShortcuts(
                        bindings: useDesktopTvLayout
                            ? <ShortcutActivator, VoidCallback>{
                                const SingleActivator(
                                  LogicalKeyboardKey.arrowDown,
                                ): () =>
                                    _requestFocus(_kidSwitchFocusNode),
                              }
                            : const <ShortcutActivator, VoidCallback>{},
                        child: TextField(
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          enabled: !_isLoading,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: l10n.hintUsername,
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: const Color(0xFF2C2C2E),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profil enfant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          flex: 6,
                          child: Text(
                            'Active le filtre PEGI. Le code PIN reste optionnel.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Focus(
                          canRequestFocus: false,
                          onKeyEvent: (_, event) => useDesktopTvLayout
                              ? _handleDirectionalKey(
                                  event,
                                  up: _nameFocusNode,
                                  down: _isKid
                                      ? _firstPegiFocusNode
                                      : bottomActionTarget,
                                  blockLeft: false,
                                  blockRight: false,
                                )
                              : KeyEventResult.ignored,
                          child: ListenableBuilder(
                            listenable: _kidSwitchFocusNode,
                            builder: (context, _) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: _kidSwitchFocusNode.hasFocus
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Switch(
                                  focusNode: _kidSwitchFocusNode,
                                  value: _isKid,
                                  onChanged: _isLoading
                                      ? null
                                      : (v) {
                                          setState(() {
                                            _isKid = v;
                                            if (!v) {
                                              _pin = null;
                                              _pinConfirmationMessage = null;
                                            } else {
                                              _pegiLimit = 12;
                                            }
                                            _error = null;
                                          });
                                        },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_isKid) ...[
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Limite d\'âge',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.start,
                        children: [3, 7, 12, 16, 18]
                            .asMap()
                            .entries
                            .map((entry) {
                              final index = entry.key;
                              final value = entry.value;
                              final selected = _pegiLimit == value;

                              final chip = ChoiceChip(
                                focusNode: _pegiFocusNodes[index],
                                label: Text('PEGI $value'),
                                selected: selected,
                                onSelected: _isLoading
                                    ? null
                                    : (_) => setState(() {
                                        _pegiLimit = value;
                                        _error = null;
                                      }),
                                selectedColor: accentColor,
                                backgroundColor: const Color(0xFF2C2C2E),
                                labelStyle: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                              );

                              if (!useDesktopTvLayout) {
                                return chip;
                              }

                              return Focus(
                                canRequestFocus: false,
                                onKeyEvent: (_, event) => _handleDirectionalKey(
                                  event,
                                  left: index > 0
                                      ? _pegiFocusNodes[index - 1]
                                      : null,
                                  right: index + 1 < _pegiFocusNodes.length
                                      ? _pegiFocusNodes[index + 1]
                                      : null,
                                  up: _kidSwitchFocusNode,
                                  down: _pinButtonFocusNode,
                                  blockLeft: index == 0,
                                  blockRight:
                                      index == _pegiFocusNodes.length - 1,
                                ),
                                child: chip,
                              );
                            })
                            .toList(growable: false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Code pin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: Focus(
                          canRequestFocus: false,
                          onKeyEvent: (_, event) => useDesktopTvLayout
                              ? _handleDirectionalKey(
                                  event,
                                  up: _firstPegiFocusNode,
                                  down: bottomActionTarget,
                                )
                              : KeyEventResult.ignored,
                          child: ProfileDialogFocusBorder(
                            focusNode: _pinButtonFocusNode,
                            child: ElevatedButton(
                              focusNode: _pinButtonFocusNode,
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      if (!mounted) return;
                                      final pin = await showDialog<String>(
                                        context: context,
                                        builder: (ctx) => _PinPromptDialog(
                                          title: l10n.profilePinSetLabel,
                                          confirmLabel: l10n.actionConfirm,
                                        ),
                                      );
                                      if (!mounted) return;
                                      final trimmed = pin?.trim();
                                      if (trimmed == null || trimmed.isEmpty) {
                                        return;
                                      }
                                      setState(() {
                                        _pin = trimmed;
                                        _error = null;
                                        _pinConfirmationMessage =
                                            l10n.profilePinSaved;
                                      });
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: Text(
                                _pin == null
                                    ? l10n.profilePinSetLabel
                                    : l10n.profilePinEditLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_pinConfirmationMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _pinConfirmationMessage!,
                          style:
                              theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.secondary,
                              ) ??
                              TextStyle(color: theme.colorScheme.secondary),
                        ),
                      ],
                    ],
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Focus(
                        canRequestFocus: false,
                        onKeyEvent: (_, event) => useDesktopTvLayout
                            ? _handleDirectionalKey(
                                event,
                                right: canCreate
                                    ? _confirmButtonFocusNode
                                    : null,
                                up: _isKid
                                    ? _pinButtonFocusNode
                                    : _kidSwitchFocusNode,
                                blockLeft: true,
                                blockRight: !canCreate,
                                blockDown: true,
                              )
                            : KeyEventResult.ignored,
                        child: ProfileDialogFocusBorder(
                          focusNode: _cancelButtonFocusNode,
                          child: OutlinedButton(
                            focusNode: _cancelButtonFocusNode,
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.of(context).pop(false),
                            style: _destructiveCancelButtonStyle(),
                            child: Text(
                              l10n.actionCancel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Focus(
                        canRequestFocus: false,
                        onKeyEvent: (_, event) => useDesktopTvLayout
                            ? _handleDirectionalKey(
                                event,
                                left: _cancelButtonFocusNode,
                                up: _isKid
                                    ? _pinButtonFocusNode
                                    : _kidSwitchFocusNode,
                                blockRight: true,
                                blockDown: true,
                              )
                            : KeyEventResult.ignored,
                        child: ProfileDialogFocusBorder(
                          focusNode: _confirmButtonFocusNode,
                          child: ElevatedButton(
                            focusNode: _confirmButtonFocusNode,
                            onPressed: canCreate ? _createProfile : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    l10n.actionConfirm,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!useDesktopTvLayout) {
      return dialog;
    }

    return MoviOverlayFocusScope(
      initialFocusNode: _nameFocusNode,
      fallbackFocusNode: bottomActionTarget,
      triggerFocusNode: widget.triggerFocusNode,
      originRegionId: AppFocusRegionId.settingsPrimary,
      fallbackRegionId: AppFocusRegionId.settingsPrimary,
      debugLabel: 'CreateProfileDialogOverlay',
      child: dialog,
    );
  }
}

class _PinPromptDialog extends StatefulWidget {
  const _PinPromptDialog({required this.title, required this.confirmLabel});

  final String title;
  final String confirmLabel;

  @override
  State<_PinPromptDialog> createState() => _PinPromptDialogState();
}

class _PinPromptDialogState extends State<_PinPromptDialog> {
  final controller = TextEditingController();
  bool _obscurePin = true;
  late final FocusNode _pinFieldFocusNode;
  late final FocusNode _cancelButtonFocusNode;
  late final FocusNode _confirmButtonFocusNode;

  @override
  void initState() {
    super.initState();
    _pinFieldFocusNode = FocusNode(debugLabel: 'CreateProfilePinField');
    _cancelButtonFocusNode = FocusNode(debugLabel: 'CreateProfilePinCancel');
    _confirmButtonFocusNode = FocusNode(debugLabel: 'CreateProfilePinConfirm');
  }

  @override
  void dispose() {
    controller.dispose();
    _pinFieldFocusNode.dispose();
    _cancelButtonFocusNode.dispose();
    _confirmButtonFocusNode.dispose();
    super.dispose();
  }

  bool _useDesktopTvLayout(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenType = ScreenTypeResolver.instance.resolve(
      size.width,
      size.height,
    );
    return screenType == ScreenType.desktop || screenType == ScreenType.tv;
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

  KeyEventResult _handleDialogBackKey(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop(null);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  ButtonStyle _destructiveCancelButtonStyle() {
    return OutlinedButton.styleFrom(
      side: const BorderSide(color: Colors.red),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final useDesktopTvLayout = _useDesktopTvLayout(context);

    final dialog = Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ModalContentWidth(
        maxWidth: 420,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Focus(
            canRequestFocus: false,
            onKeyEvent: (_, event) => useDesktopTvLayout
                ? _handleDialogBackKey(event)
                : KeyEventResult.ignored,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Focus(
                  canRequestFocus: false,
                  onKeyEvent: (_, event) => useDesktopTvLayout
                      ? _handleDirectionalKey(
                          event,
                          down: _cancelButtonFocusNode,
                          blockUp: true,
                          blockLeft: false,
                          blockRight: false,
                        )
                      : KeyEventResult.ignored,
                  child: TextField(
                    controller: controller,
                    focusNode: _pinFieldFocusNode,
                    keyboardType: TextInputType.number,
                    obscureText: _obscurePin,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'PIN (4-6 chiffres)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2E),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePin = !_obscurePin;
                          });
                        },
                        icon: Icon(
                          _obscurePin ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white70,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Focus(
                        canRequestFocus: false,
                        onKeyEvent: (_, event) => useDesktopTvLayout
                            ? _handleDirectionalKey(
                                event,
                                right: _confirmButtonFocusNode,
                                up: _pinFieldFocusNode,
                                blockLeft: true,
                                blockDown: true,
                              )
                            : KeyEventResult.ignored,
                        child: OutlinedButton(
                          focusNode: _cancelButtonFocusNode,
                          onPressed: () => Navigator.of(context).pop(null),
                          style: _destructiveCancelButtonStyle(),
                          child: const Text(
                            'Annuler',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Focus(
                        canRequestFocus: false,
                        onKeyEvent: (_, event) => useDesktopTvLayout
                            ? _handleDirectionalKey(
                                event,
                                left: _cancelButtonFocusNode,
                                up: _pinFieldFocusNode,
                                blockRight: true,
                                blockDown: true,
                              )
                            : KeyEventResult.ignored,
                        child: ElevatedButton(
                          focusNode: _confirmButtonFocusNode,
                          onPressed: () =>
                              Navigator.of(context).pop(controller.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            widget.confirmLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!useDesktopTvLayout) {
      return dialog;
    }

    return MoviOverlayFocusScope(
      initialFocusNode: _pinFieldFocusNode,
      fallbackFocusNode: _cancelButtonFocusNode,
      debugLabel: 'CreateProfilePinDialogOverlay',
      child: dialog,
    );
  }
}
