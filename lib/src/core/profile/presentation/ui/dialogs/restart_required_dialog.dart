import 'package:flutter/material.dart';

import 'package:movi/src/core/widgets/app_restart.dart';

/// Dialog affiché après création d'un profil enfant pour demander un redémarrage
class RestartRequiredDialog extends StatelessWidget {
  const RestartRequiredDialog({super.key});

  /// Affiche le dialog et retourne true si l'utilisateur choisit de redémarrer
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const RestartRequiredDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: size.height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.child_care, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Profil enfant créé',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Un profil enfant a été créé. Pour sécuriser l\'application et précharger les classifications d\'âge, il est recommandé de redémarrer l\'application.\n\n'
                'Souhaites-tu redémarrer maintenant ?',
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Plus tard'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                        AppRestart.restartApp(context);
                      },
                      child: const Text('Redémarrer maintenant'),
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
