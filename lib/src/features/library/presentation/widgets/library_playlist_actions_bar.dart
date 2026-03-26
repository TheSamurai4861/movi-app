import 'package:flutter/material.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';

/// Barre d'actions pour la page de détail de playlist.
///
/// Contient :
/// - Lire aléatoirement : MoviPrimaryButton qui prend toute la largeur disponible
/// - Trier : bouton rond en gris (même hauteur que le primaire) avec l'icône sort.png
class LibraryPlaylistActionsBar extends StatelessWidget {
  const LibraryPlaylistActionsBar({
    super.key,
    required this.isEmpty,
    this.onPlayRandom,
    this.onSortPressed,
    this.compact = false,
  });

  final bool isEmpty;
  final VoidCallback? onPlayRandom;
  final VoidCallback? onSortPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final buttonSize = compact ? 40.0 : 48.0;
    final iconSize = compact ? 20.0 : 24.0;

    return Row(
      children: [
        // Bouton "Lire aléatoirement" - MoviPrimaryButton qui prend toute la largeur
        Expanded(
          child: MoviPrimaryButton(
            label: localizations.playlistPlayRandomly,
            onPressed: isEmpty ? null : onPlayRandom,
            expand: true,
            height: buttonSize,
          ),
        ),
        const SizedBox(width: 16),
        // Bouton rond de tri (même hauteur que le primaire)
        SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: Material(
            color: isEmpty
                ? const Color(0xFF1A1A1A)
                : const Color(0xFF2A2A2A),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: isEmpty ? null : onSortPressed,
              customBorder: const CircleBorder(),
              child: Center(
                child: Image.asset(
                  AppAssets.iconSort,
                  width: iconSize,
                  height: iconSize,
                  color: isEmpty ? Colors.white38 : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
