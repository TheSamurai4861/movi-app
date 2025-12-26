import 'package:flutter/material.dart';

/// Barre d'application personnalisée pour la page de détail de playlist.
///
/// Affiche un bouton retour et optionnellement un menu (trois points verticaux)
/// pour les playlists utilisateur.
class LibraryPlaylistAppBar extends StatelessWidget {
  const LibraryPlaylistAppBar({
    super.key,
    required this.onBack,
    this.onMenu,
    this.showMenu = false,
  });

  final VoidCallback onBack;
  final VoidCallback? onMenu;
  final bool showMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bouton retour
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onBack,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
          // Bouton menu (si showMenu)
          if (showMenu && onMenu != null)
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: onMenu,
              tooltip: 'Menu',
            )
          else
            const SizedBox(width: 48), // Espace équivalent pour centrage
        ],
      ),
    );
  }
}

