import 'package:flutter/material.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';

/// Barre d'actions pour la page de détail de playlist.
///
/// Contient :
/// - Lire aléatoirement : MoviPrimaryButton qui prend toute la largeur disponible
/// - Trier : bouton rond en gris (même hauteur que le primaire) avec l'icône de tri
class LibraryPlaylistActionsBar extends StatelessWidget {
  const LibraryPlaylistActionsBar({
    super.key,
    required this.isEmpty,
    this.onPlayRandom,
    this.onSortPressed,
    this.compact = false,
    this.playRandomFocusNode,
    this.sortFocusNode,
    this.onPlayRandomKeyEvent,
    this.onSortKeyEvent,
  });

  final bool isEmpty;
  final VoidCallback? onPlayRandom;
  final VoidCallback? onSortPressed;
  final bool compact;
  final FocusNode? playRandomFocusNode;
  final FocusNode? sortFocusNode;
  final KeyEventResult Function(KeyEvent event)? onPlayRandomKeyEvent;
  final KeyEventResult Function(KeyEvent event)? onSortKeyEvent;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final buttonSize = compact ? 40.0 : 48.0;
    final iconSize = compact ? 20.0 : 24.0;

    return Row(
      children: [
        // Bouton "Lire aléatoirement" - MoviPrimaryButton qui prend toute la largeur
        Expanded(
          child: Focus(
            canRequestFocus: false,
            onKeyEvent: (_, event) =>
                onPlayRandomKeyEvent?.call(event) ?? KeyEventResult.ignored,
            child: MoviPrimaryButton(
              label: localizations.playlistPlayRandomly,
              focusNode: playRandomFocusNode,
              onPressed: isEmpty ? null : onPlayRandom,
              expand: true,
              height: buttonSize,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Bouton rond de tri (même hauteur que le primaire)
        SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: Focus(
            canRequestFocus: false,
            onKeyEvent: (_, event) =>
                onSortKeyEvent?.call(event) ?? KeyEventResult.ignored,
            child: MoviFocusableAction(
              focusNode: sortFocusNode,
              onPressed: isEmpty ? null : onSortPressed,
              semanticLabel: localizations.playlistSortByTitle,
              builder: (context, state) {
                return MoviFocusFrame(
                  scale: state.focused ? 1.04 : 1,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor: isEmpty
                      ? const Color(0xFF1A1A1A)
                      : const Color(0xFF2A2A2A),
                  borderColor: state.focused
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderWidth: 2,
                  child: Center(
                    child: MoviAssetIcon(
                      AppAssets.iconSort,
                      width: iconSize,
                      height: iconSize,
                      color: isEmpty ? Colors.white38 : Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
