import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/domain/repositories/profile_repository.dart';
import 'package:movi/src/core/profile/presentation/providers/profiles_providers.dart';

/// Dialog pour gÃƒÆ’Ã‚Â©rer un profil (rename / delete).
///
/// Clean rules respectÃƒÆ’Ã‚Â©es :
/// - UI dans `presentation/ui/dialogs/`
/// - Aucun import depuis `features/*`
/// - Utilise l'entity domain `Profile` (pas de "SupabaseProfile")
class ManageProfileDialog extends ConsumerStatefulWidget {
  const ManageProfileDialog({
    super.key,
    required this.profile,
  });

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
  ConsumerState<ManageProfileDialog> createState() => _ManageProfileDialogState();
}

class _ManageProfileDialogState extends ConsumerState<ManageProfileDialog> {
  late final TextEditingController _nameController;
  late bool _isKid;
  int? _pegiLimit;
  late bool _hasPin;

  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _isKid = widget.profile.isKid;
    _pegiLimit = widget.profile.pegiLimit;
    _hasPin = widget.profile.hasPin;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = l10n.errorFillFields);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final bool parentalChanged =
        _isKid != widget.profile.isKid || _pegiLimit != widget.profile.pegiLimit;

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
        insetPadding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: size.width - 40,
          ),
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
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
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
        setState(() => _error = 'PIN incorrect');
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
    });

    try {
      final svc = ref.read(parental.profilePinEdgeServiceProvider);
      await svc.setPin(profileId: widget.profile.id, pin: trimmed);
      await ref.read(profilesControllerProvider.notifier).refresh();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _hasPin = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Erreur: $e';
      });
    }
  }

  Future<void> _removePin() async {
    if (_busy || !_hasPin) return;

    final pin = await showDialog<String>(
      context: context,
      builder: (ctx) => const _RemovePinDialog(),
    );
    final trimmed = pin?.trim();
    if (trimmed == null || trimmed.isEmpty) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final svc = ref.read(parental.profilePinEdgeServiceProvider);
      final cleared =
          await svc.clearPin(profileId: widget.profile.id, pin: trimmed);
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
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Erreur: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 20,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: size.width - 40,
          maxHeight: size.height * 0.9,
        ),
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
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
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
                  TextField(
                    controller: _nameController,
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
                          'Active le contrôle parental (PEGI + PIN).',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: _isKid,
                        onChanged: _busy
                            ? null
                            : (v) {
                                setState(() {
                                  _isKid = v;
                                  if (!v) _pegiLimit = null;
                                  _error = null;
                                });
                              },
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
                      children: [3, 7, 12, 16, 18].map((v) {
                        final selected = _pegiLimit == v;
                        return ChoiceChip(
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
                      }).toList(growable: false),
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
                      child: ElevatedButton(
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
                  ] else ...[
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _busy ? null : _setOrChangePin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: (_busy || !_hasPin) ? null : _removePin,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
                      ],
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
                    child: OutlinedButton(
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _busy ? null : _save,
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
                ],
              ),
            ],
          ),
        ),
      ),
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

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 20,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: size.width - 40,
        ),
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
                            onPressed: () => Navigator.of(context).pop(controller.text),
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
                            onPressed: () => Navigator.of(context).pop(controller.text),
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
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 20,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: size.width - 40,
        ),
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
                      onPressed: () => Navigator.of(context).pop(controller.text),
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
