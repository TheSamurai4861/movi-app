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
  });

  final bool isEmpty;
  final VoidCallback? onPlayRandom;
  final VoidCallback? onSortPressed;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Row(
      children: [
        // Bouton "Lire aléatoirement" - MoviPrimaryButton qui prend toute la largeur
        Expanded(
          child: MoviPrimaryButton(
            label: localizations.playlistPlayRandomly,
            onPressed: isEmpty ? null : onPlayRandom,
            expand: true,
            height: 48,
          ),
        ),
        const SizedBox(width: 16),
        // Bouton rond de tri (même hauteur que le primaire, 48px)
        SizedBox(
          width: 48,
          height: 48,
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
                  width: 24,
                  height: 24,
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
