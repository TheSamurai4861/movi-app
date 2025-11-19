import 'package:flutter/material.dart';

import 'package:movi/l10n/app_localizations.dart';

/// Barre d'actions pour la page de détail de playlist.
///
/// Contient trois boutons :
/// - Lire aléatoirement : démarre la lecture d'un élément aléatoire de la playlist
/// - Ajouter : permet d'ajouter un nouveau média à la playlist (playlists utilisateur uniquement)
/// - Trier : ouvre un menu de tri
class LibraryPlaylistActionsBar extends StatelessWidget {
  const LibraryPlaylistActionsBar({
    super.key,
    required this.isEmpty,
    required this.isUserPlaylist,
    this.onPlayRandom,
    this.onAddPressed,
    this.onSortPressed,
  });

  final bool isEmpty;
  final bool isUserPlaylist;
  final VoidCallback? onPlayRandom;
  final VoidCallback? onAddPressed;
  final VoidCallback? onSortPressed;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Row(
      children: [
        // Bouton "Lire aléatoirement"
        Expanded(
          flex: 2,
          child: _ActionButton(
            icon: Icons.shuffle,
            label: localizations.playlistPlayRandomly,
            onPressed: onPlayRandom,
          ),
        ),
        const SizedBox(width: 12),
        // Bouton "Ajouter" (playlists utilisateur uniquement)
        if (isUserPlaylist)
          Expanded(
            child: _ActionButton(
              icon: Icons.add,
              label: localizations.playlistAddButton,
              onPressed: onAddPressed,
            ),
          ),
        if (isUserPlaylist) const SizedBox(width: 12),
        // Bouton "Trier"
        Expanded(
          child: _ActionButton(
            icon: Icons.sort,
            label: localizations.playlistSortByTitle,
            onPressed: onSortPressed,
          ),
        ),
      ],
    );
  }
}

/// Bouton d'action avec icône et label
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Material(
      color: enabled ? const Color(0xFF2A2A2A) : const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: enabled ? Colors.white : Colors.white38,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: enabled ? Colors.white : Colors.white38,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
