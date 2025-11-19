import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_placeholder_card.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;

enum LibraryPlaylistType {
  inProgress,
  favoriteMovies,
  favoriteSeries,
  watchHistory,
  userPlaylist,
  actor,
}

class LibraryPlaylistCard extends ConsumerWidget {
  const LibraryPlaylistCard({
    super.key,
    required this.title,
    required this.itemCount,
    required this.type,
    this.isPinned = false,
    this.onTap,
    this.onLongPress,
    this.photo, // Photo de profil pour les artistes ou image hero pour les sagas
    this.showItemCount =
        true, // Par défaut afficher le compteur, sauf pour les sagas
  });

  final String title;
  final int itemCount;
  final LibraryPlaylistType type;
  final bool isPinned;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Uri?
  photo; // Photo de profil pour les artistes ou image hero pour les sagas
  final bool showItemCount; // Contrôle l'affichage du compteur d'éléments

  /// Génère une couleur foncée à partir de l'accent color pour la partie sombre du gradient.
  Color _darkenColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    // Réduire la luminosité à environ 15-20% et réduire la saturation
    return hsl
        .withLightness(0.15.clamp(0.0, 1.0))
        .withSaturation((hsl.saturation * 0.7).clamp(0.0, 1.0))
        .toColor();
  }

  Widget _getIcon() {
    switch (type) {
      case LibraryPlaylistType.inProgress:
        return const Icon(
          Icons.play_circle_outline,
          color: Colors.white,
          size: 40,
        );
      case LibraryPlaylistType.favoriteMovies:
        return Image.asset(
          AppAssets.iconMovie,
          width: 40,
          height: 40,
          color: Colors.white,
        );
      case LibraryPlaylistType.favoriteSeries:
        return Image.asset(
          AppAssets.iconSerie,
          width: 40,
          height: 40,
          color: Colors.white,
        );
      case LibraryPlaylistType.watchHistory:
        return Image.asset(
          AppAssets.iconAvancer,
          width: 40,
          height: 40,
          color: Colors.white,
        );
      case LibraryPlaylistType.userPlaylist:
        return Image.asset(
          AppAssets.iconPlaylist,
          width: 40,
          height: 40,
          color: Colors.white,
        );
      case LibraryPlaylistType.actor:
        return MoviPlaceholderCard(
          type: PlaceholderType.person,
          width: 40,
          height: 40,
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(asp.currentAccentColorProvider);
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Carré avec photo de profil pour les artistes, image hero pour les sagas, ou dégradé avec icône pour les autres
            Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: (type == LibraryPlaylistType.actor || photo != null)
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [accentColor, _darkenColor(accentColor)],
                      ),
                color: (type == LibraryPlaylistType.actor || photo != null)
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : null,
              ),
              child: photo != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        photo!.toString(),
                        width: 75,
                        height: 75,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(child: _getIcon()),
                      ),
                    )
                  : Center(child: _getIcon()),
            ),
            const SizedBox(width: 16),
            // Titre et informations
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ) ??
                        const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Pour les artistes et les sagas, ne pas afficher le compteur d'éléments
                  if (type != LibraryPlaylistType.actor && showItemCount) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (isPinned) ...[
                          Icon(Icons.push_pin, size: 20, color: accentColor),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          '$itemCount ${itemCount == 1 ? 'élément' : 'éléments'}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ) ??
                              TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
