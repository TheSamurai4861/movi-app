import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/focus/movi_overlay_focus_scope.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/domain/repositories/profile_repository.dart';
import 'package:movi/src/core/profile/presentation/providers/profiles_providers.dart';
import 'package:movi/src/core/profile/presentation/ui/dialogs/profile_dialog_focus_border.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/core/widgets/modal_content_width.dart';

/// Dialog pour gÃƒÆ’Ã‚Â©rer un profil (rename / delete).
///
/// Clean rules respectÃƒÆ’Ã‚Â©es :
/// - UI dans `presentation/ui/dialogs/`
/// - Aucun import depuis `features/*`
/// - Utilise l'entity domain `Profile` (pas de "SupabaseProfile")
class ManageProfileDialog extends ConsumerStatefulWidget {
  const ManageProfileDialog({super.key, required this.profile});

  final Profile profile;

  static Future<void> show(
    BuildContext context, {
    required Profile profile,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ManageProfileDialog(profile: profile),
    );
  }

  @override
  ConsumerState<ManageProfileDialog> createState() =>
      _ManageProfileDialogState();
}

class _ManageProfileDialogState extends ConsumerState<ManageProfileDialog> {
  late final TextEditingController _nameController;
  late final FocusNode _nameFocusNode;
  late final FocusNode _kidSwitchFocusNode;
  late final FocusNode _firstPegiFocusNode;
  late final List<FocusNode> _pegiFocusNodes;
  late final FocusNode _pinPrimaryFocusNode;
  late final FocusNode _pinSecondaryFocusNode;
  late final FocusNode _deleteFocusNode;
  late final FocusNode _saveFocusNode;
  late bool _isKid;
  int? _pegiLimit;
  late bool _hasPin;

  bool _busy = false;
  String? _error;
  String? _pinConfirmationMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _nameFocusNode = FocusNode(debugLabel: 'ManageProfileName');
    _kidSwitchFocusNode = FocusNode(debugLabel: 'ManageProfileKidSwitch');
    _firstPegiFocusNode = FocusNode(debugLabel: 'ManageProfileFirstPegi');
    _pegiFocusNodes = List<FocusNode>.generate(
      5,
      (index) => index == 0
          ? _firstPegiFocusNode
          : FocusNode(debugLabel: 'ManageProfilePegi$index'),
    );
    _pinPrimaryFocusNode = FocusNode(debugLabel: 'ManageProfilePinPrimary');
    _pinSecondaryFocusNode = FocusNode(debugLabel: 'ManageProfilePinSecondary');
    _deleteFocusNode = FocusNode(debugLabel: 'ManageProfileDelete');
    _saveFocusNode = FocusNode(debugLabel: 'ManageProfileSave');
    _isKid = widget.profile.isKid;
    _pegiLimit = widget.profile.pegiLimit;
    _hasPin = widget.profile.hasPin;
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
    _pinPrimaryFocusNode.dispose();
    _pinSecondaryFocusNode.dispose();
    _deleteFocusNode.dispose();
    _saveFocusNode.dispose();
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

  bool get _requiresPinToDisableKidProfile =>
      widget.profile.isKid && !_isKid && !_hasPin;

  bool get _canRemovePinSafely => !_isKid && !widget.profile.isKid;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = l10n.errorFillFields);
      return;
    }

    if (_requiresPinToDisableKidProfile) {
      setState(
        () =>
            _error = 'Définissez un code PIN avant d’activer le profil enfant.',
      );
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final bool parentalChanged =
        _isKid != widget.profile.isKid ||
        _pegiLimit != widget.profile.pegiLimit;

    if (parentalChanged && _hasPin) {
      final ok = await _verifyPin();
      if (!ok) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = 'PIN incorrect';
        });
        return;
      }
    }

    final Object? pegiLimitArg = (_pegiLimit != widget.profile.pegiLimit)
        ? _pegiLimit
        : ProfileRepository.noChange;

    final ok = await ref
        .read(profilesControllerProvider.notifier)
        .updateProfile(
          profileId: widget.profile.id,
          name: name,
          isKid: _isKid != widget.profile.isKid ? _isKid : null,
          pegiLimit: pegiLimitArg,
        );

    if (!mounted) return;

    if (ok) {
      // Si on a modifié les paramètres parentaux, réinitialiser la session de déverrouillage
      if (parentalChanged) {
        try {
          final sessionSvc = ref.read(parental.parentalSessionServiceProvider);
          await sessionSvc.lock(widget.profile.id);
        } catch (_) {
          // Best-effort: ne pas bloquer la fermeture du dialog si ça échoue
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } else {
      setState(() {
        _busy = false;
        _error = l10n.errorUnknown;
      });
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: size.width - 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.playlistDeleteTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.playlistDeleteConfirm(widget.profile.name),
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(ctx).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          l10n.delete,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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

    if (confirmed != true) return;

    if (_hasPin) {
      final ok = await _verifyPin();
      if (!ok) {
        if (!mounted) return;
        setState(() => _error = 'PIN incorrect');
        return;
      }
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final ok = await ref
        .read(profilesControllerProvider.notifier)
        .deleteProfile(widget.profile.id);

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _busy = false;
        _error = l10n.errorUnknown;
      });
    }
  }

  Future<bool> _verifyPin({bool isDeleteAction = false}) async {
    if (!mounted) return false;

    final pin = await showDialog<String>(
      context: context,
      builder: (ctx) => _PinPromptDialog(
        title: 'Vérification PIN',
        confirmLabel: isDeleteAction ? 'Supprimer' : 'Vérifier',
        isDeleteAction: isDeleteAction,
      ),
    );
    final trimmed = pin?.trim();
    if (trimmed == null || trimmed.isEmpty) return false;

    try {
      final svc = ref.read(parental.profilePinEdgeServiceProvider);
      return await svc.verifyPin(profileId: widget.profile.id, pin: trimmed);
    } catch (_) {
      return false;
    }
  }

  Future<void> _setOrChangePin() async {
    if (_busy) return;

    if (_hasPin) {
      final ok = await _verifyPin();
      if (!ok) {
        if (!mounted) return;
        setState(() {
          _error = 'PIN incorrect';
          _pinConfirmationMessage = null;
        });
        return;
      }
    }

    if (!mounted) return;
    final newPin = await showDialog<String>(
      context: context,
      builder: (ctx) => _PinPromptDialog(
        title: widget.profile.hasPin ? 'Nouveau PIN' : 'Définir un PIN',
        confirmLabel: 'Enregistrer',
      ),
    );
    final trimmed = newPin?.trim();
    if (trimmed == null || trimmed.isEmpty) return;

    setState(() {
      _busy = true;
      _error = null;
      _pinConfirmationMessage = null;
    });

    try {
      final svc = ref.read(parental.profilePinEdgeServiceProvider);
      await svc.setPin(profileId: widget.profile.id, pin: trimmed);
      await ref.read(profilesControllerProvider.notifier).refresh();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _hasPin = true;
        _pinConfirmationMessage = widget.profile.hasPin
            ? 'PIN mis à jour.'
            : 'PIN enregistré.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Erreur: $e';
        _pinConfirmationMessage = null;
      });
    }
  }

  Future<void> _removePin() async {
    if (_busy || !_hasPin) return;

    if (!_canRemovePinSafely) {
      setState(() {
        _error =
            'Désactivez et enregistrez d’abord le profil enfant avant de supprimer le code PIN.';
        _pinConfirmationMessage = null;
      });
      return;
    }

    final pin = await showDialog<String>(
      context: context,
      builder: (ctx) => const _RemovePinDialog(),
    );
    final trimmed = pin?.trim();
    if (trimmed == null || trimmed.isEmpty) return;

    setState(() {
      _busy = true;
      _error = null;
      _pinConfirmationMessage = null;
    });

    try {
      final svc = ref.read(parental.profilePinEdgeServiceProvider);
      final cleared = await svc.clearPin(
        profileId: widget.profile.id,
        pin: trimmed,
      );
      if (!cleared) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = 'PIN incorrect';
        });
        return;
      }
      await ref.read(profilesControllerProvider.notifier).refresh();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _hasPin = false;
        _pinConfirmationMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Erreur: $e';
        _pinConfirmationMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final useDesktopTvLayout = _useDesktopTvLayout(context);
    final canSave = !_busy && !_requiresPinToDisableKidProfile;

    final dialog = Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ModalContentWidth(
        maxWidth: 560,
        maxHeight: MediaQuery.of(context).size.height * 0.9,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Section Pseudo
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
                        enabled: !_busy,
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

              // Section Profil enfant
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
                      Expanded(
                        flex: 6,
                        child: const Text(
                          'Active le contrôle parental. Le code PIN reste facultatif tant que le profil reste enfant.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
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
                                    : _pinPrimaryFocusNode,
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
                                onChanged: _busy
                                    ? null
                                    : (v) {
                                        setState(() {
                                          _isKid = v;
                                          if (!v) {
                                            _pegiLimit = null;
                                          } else {
                                            _pegiLimit ??= 12;
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
                // Section Limite d'âge
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
                            final v = entry.value;
                            final selected = _pegiLimit == v;
                            final chip = ChoiceChip(
                              focusNode: _pegiFocusNodes[index],
                              label: Text('PEGI $v'),
                              selected: selected,
                              onSelected: _busy
                                  ? null
                                  : (_) => setState(() {
                                      _pegiLimit = v;
                                      _error = null;
                                    }),
                              selectedColor: accentColor,
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : Colors.white70,
                              ),
                              backgroundColor: const Color(0xFF2C2C2E),
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
                                down: _pinPrimaryFocusNode,
                                blockLeft: index == 0,
                                blockRight: index == _pegiFocusNodes.length - 1,
                              ),
                              child: chip,
                            );
                          })
                          .toList(growable: false),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Section Code pin
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
                  if (!_hasPin) ...[
                    SizedBox(
                      width: double.infinity,
                      child: Focus(
                        canRequestFocus: false,
                        onKeyEvent: (_, event) => useDesktopTvLayout
                            ? _handleDirectionalKey(
                                event,
                                up: _isKid
                                    ? _firstPegiFocusNode
                                    : _kidSwitchFocusNode,
                                down: _saveFocusNode,
                              )
                            : KeyEventResult.ignored,
                        child: ProfileDialogFocusBorder(
                          focusNode: _pinPrimaryFocusNode,
                          child: ElevatedButton(
                            focusNode: _pinPrimaryFocusNode,
                            onPressed: _busy ? null : _setOrChangePin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Définir code PIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Focus(
                            canRequestFocus: false,
                            onKeyEvent: (_, event) => useDesktopTvLayout
                                ? _handleDirectionalKey(
                                    event,
                                    up: _isKid
                                        ? _firstPegiFocusNode
                                        : _kidSwitchFocusNode,
                                    right: _pinSecondaryFocusNode,
                                    down: _saveFocusNode,
                                  )
                                : KeyEventResult.ignored,
                            child: ProfileDialogFocusBorder(
                              focusNode: _pinPrimaryFocusNode,
                              child: ElevatedButton(
                                focusNode: _pinPrimaryFocusNode,
                                onPressed: _busy ? null : _setOrChangePin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: const Text(
                                  'Changer le code PIN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: Focus(
                            canRequestFocus: false,
                            onKeyEvent: (_, event) => useDesktopTvLayout
                                ? _handleDirectionalKey(
                                    event,
                                    left: _pinPrimaryFocusNode,
                                    up: _isKid
                                        ? _firstPegiFocusNode
                                        : _kidSwitchFocusNode,
                                    down: _saveFocusNode,
                                    blockRight: true,
                                  )
                                : KeyEventResult.ignored,
                            child: ProfileDialogFocusBorder(
                              focusNode: _pinSecondaryFocusNode,
                              child: OutlinedButton(
                                focusNode: _pinSecondaryFocusNode,
                                onPressed:
                                    (_busy || !_hasPin || !_canRemovePinSafely)
                                    ? null
                                    : _removePin,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: const Text(
                                  'Supprimer le code PIN',
                                  style: TextStyle(
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
                  if (_requiresPinToDisableKidProfile) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Définissez un code PIN avant de repasser ce profil en adulte.',
                      style: TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ],
                  if (_hasPin && !_canRemovePinSafely) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Pour supprimer le code PIN, désactivez d’abord le profil enfant puis enregistrez.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
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

              if (_error != null) ...[
                const SizedBox(height: 24),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
              ],

              const SizedBox(height: 24),

              // Section Actions
              Row(
                children: [
                  Expanded(
                    child: Focus(
                      canRequestFocus: false,
                      onKeyEvent: (_, event) => useDesktopTvLayout
                          ? _handleDirectionalKey(
                              event,
                              right: _saveFocusNode,
                              up: _pinPrimaryFocusNode,
                              blockLeft: true,
                              blockDown: true,
                            )
                          : KeyEventResult.ignored,
                      child: ProfileDialogFocusBorder(
                        focusNode: _deleteFocusNode,
                        child: OutlinedButton(
                          focusNode: _deleteFocusNode,
                          onPressed: _busy ? null : _delete,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            l10n.delete,
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
                              left: _deleteFocusNode,
                              up: _pinPrimaryFocusNode,
                              blockRight: true,
                              blockDown: true,
                            )
                          : KeyEventResult.ignored,
                      child: ProfileDialogFocusBorder(
                        focusNode: _saveFocusNode,
                        child: ElevatedButton(
                          focusNode: _saveFocusNode,
                          onPressed: canSave ? _save : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _busy
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
    );

    if (!useDesktopTvLayout) {
      return dialog;
    }

    return MoviOverlayFocusScope(
      initialFocusNode: _nameFocusNode,
      fallbackFocusNode: _saveFocusNode,
      debugLabel: 'ManageProfileDialogOverlay',
      child: dialog,
    );
  }
}

class _PinPromptDialog extends StatefulWidget {
  const _PinPromptDialog({
    required this.title,
    required this.confirmLabel,
    this.isDeleteAction = false,
  });

  final String title;
  final String confirmLabel;
  final bool isDeleteAction;

  @override
  State<_PinPromptDialog> createState() => _PinPromptDialogState();
}

class _PinPromptDialogState extends State<_PinPromptDialog> {
  final controller = TextEditingController();
  bool _obscurePin = true;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ModalContentWidth(
        maxWidth: 420,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
              TextField(
                controller: controller,
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
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: widget.isDeleteAction
                        ? ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(null),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Annuler',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(null),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: accentColor),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: widget.isDeleteAction
                        ? OutlinedButton(
                            onPressed: () =>
                                Navigator.of(context).pop(controller.text),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              foregroundColor: Colors.white,
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
                          )
                        : ElevatedButton(
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemovePinDialog extends StatefulWidget {
  const _RemovePinDialog();

  @override
  State<_RemovePinDialog> createState() => _RemovePinDialogState();
}

class _RemovePinDialogState extends State<_RemovePinDialog> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ModalContentWidth(
        maxWidth: 420,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Supprimer le PIN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'PIN (4-6 chiffres)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: accentColor),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(controller.text),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Supprimer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
    );
  }
}
