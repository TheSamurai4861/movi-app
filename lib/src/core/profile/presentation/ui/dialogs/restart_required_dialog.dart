import 'package:flutter/material.dart';

import 'package:movi/src/core/widgets/app_restart.dart';

/// Dialog affiché après création d'un profil enfant pour demander un redémarrage
class RestartRequiredDialog extends StatelessWidget {
  const RestartRequiredDialog({super.key});

  static const double _mobileActionsBreakpoint = 420;

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
    final theme = Theme.of(context);

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
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow =
                      constraints.maxWidth < _mobileActionsBreakpoint;

                  final laterButton = SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        textStyle: theme.textTheme.labelLarge,
                      ),
                      child: const Text('Plus tard'),
                    ),
                  );

                  final restartButton = SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                        AppRestart.resetBootstrapState();
                        AppRestart.restartApp(context);
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        textStyle: theme.textTheme.labelLarge,
                      ),
                      child: const Text('Redémarrer maintenant'),
                    ),
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        restartButton,
                        const SizedBox(height: 12),
                        laterButton,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: laterButton),
                      const SizedBox(width: 12),
                      Expanded(child: restartButton),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
