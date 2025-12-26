import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/presentation/providers/profiles_providers.dart';
import 'package:movi/src/core/profile/presentation/ui/dialogs/restart_required_dialog.dart';

/// Modal dialog pour crÃƒÆ’Ã‚Â©er un nouveau profil.
class CreateProfileDialog extends ConsumerStatefulWidget {
  const CreateProfileDialog({super.key});

  /// Affiche la modal et retourne true si un profil a ÃƒÆ’Ã‚Â©tÃƒÆ’Ã‚Â© crÃƒÆ’Ã‚Â©ÃƒÆ’Ã‚Â©.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const CreateProfileDialog(),
    );
    return result ?? false;
  }

  @override
  ConsumerState<CreateProfileDialog> createState() => _CreateProfileDialogState();
}

class _CreateProfileDialogState extends ConsumerState<CreateProfileDialog> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _isKid = false;
  int _pegiLimit = 12;
  String? _pin;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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

    // Utiliser la couleur accent du thème
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

    // If kid profile: require PIN + set restrictions.
    if (_isKid) {
      final pin = _pin?.trim();
      if (pin == null || !RegExp(r'^\d{4,6}$').hasMatch(pin)) {
        setState(() {
          _isLoading = false;
          _error = 'PIN requis (4-6 chiffres)';
        });
        return;
      }

      try {
        final pinSvc = ref.read(parental.profilePinEdgeServiceProvider);
        await pinSvc.setPin(profileId: created.id, pin: pin);

        final ok = await ref.read(profilesControllerProvider.notifier).updateProfile(
          profileId: created.id,
          isKid: true,
          pegiLimit: _pegiLimit,
        );

        if (!ok) {
          // Keep invariant: no "kid profile" without proper config.
          await ref.read(profilesControllerProvider.notifier).deleteProfile(created.id);
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _error = 'Impossible d\'appliquer le contrôle parental';
          });
          return;
        }

        await ref.read(profilesControllerProvider.notifier).refresh();
      } catch (e) {
        // Best-effort rollback: delete the profile if PIN setup fails.
        await ref.read(profilesControllerProvider.notifier).deleteProfile(created.id);
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'Erreur PIN: $e';
        });
        return;
      }

      // Afficher la modal de redémarrage pour les profils enfants
      if (!mounted) return;
      final shouldRestart = await RestartRequiredDialog.show(context);
      if (shouldRestart) {
        // Le redémarrage est géré dans le dialog
        return;
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    final bool canCreate = !_isLoading &&
        _nameController.text.trim().isNotEmpty &&
        (!_isKid ||
            (_pin != null && RegExp(r'^\d{4,6}$').hasMatch(_pin!.trim())));

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
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
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
                          'Oblige un PIN et active le filtre PEGI.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: _isKid,
                        onChanged: _isLoading
                            ? null
                            : (v) {
                                setState(() {
                                  _isKid = v;
                                  if (!v) {
                                    _pin = null;
                                  } else {
                                    _pegiLimit = 12;
                                  }
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
                          onSelected: _isLoading ? null : (_) => setState(() => _pegiLimit = v),
                          selectedColor: accentColor,
                          backgroundColor: const Color(0xFF2C2C2E),
                          labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70),
                        );
                      }).toList(growable: false),
                    ),
                  ],
                ),
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                if (!mounted) return;
                                final pin = await showDialog<String>(
                                  context: context,
                                  builder: (ctx) => const _PinPromptDialog(
                                    title: 'Définir un PIN',
                                    confirmLabel: 'Valider',
                                  ),
                                );
                                if (!mounted) return;
                                final trimmed = pin?.trim();
                                if (trimmed == null || trimmed.isEmpty) return;
                                setState(() => _pin = trimmed);
                              },
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
                  ],
                ),
              ],

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
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: accentColor),
                        foregroundColor: Colors.white,
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
                    child: ElevatedButton(
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
  });

  final String title;
  final String confirmLabel;

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
                    child: ElevatedButton(
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
