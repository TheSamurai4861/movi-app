import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

enum LibraryPlaylistType {
  favoriteMovies,
  favoriteSeries,
  watchHistory,
  userPlaylist,
  actor,
}

class LibraryPlaylistCard extends StatelessWidget {
  const LibraryPlaylistCard({
    super.key,
    required this.title,
    required this.itemCount,
    required this.type,
    this.isPinned = false,
    this.onTap,
    this.photo, // Photo de profil pour les artistes
  });

  final String title;
  final int itemCount;
  final LibraryPlaylistType type;
  final bool isPinned;
  final VoidCallback? onTap;
  final Uri? photo; // Photo de profil pour les artistes

  Widget _getIcon() {
    switch (type) {
      case LibraryPlaylistType.favoriteMovies:
        return const Icon(Icons.movie, color: Colors.white, size: 40);
      case LibraryPlaylistType.favoriteSeries:
        return const Icon(Icons.live_tv, color: Colors.white, size: 40);
      case LibraryPlaylistType.watchHistory:
        return Image.asset(
          AppAssets.iconAvancer,
          width: 40,
          height: 40,
          color: Colors.white,
        );
      case LibraryPlaylistType.userPlaylist:
        return const Icon(Icons.playlist_play, color: Colors.white, size: 40);
      case LibraryPlaylistType.actor:
        return Image.asset(
          AppAssets.placeholderPersonActor,
          width: 40,
          height: 40,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Carré avec photo de profil pour les artistes, ou dégradé avec icône pour les autres
            Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: type == LibraryPlaylistType.actor
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF5493DE),
                          Color(0xFF0D2745),
                        ],
                      ),
                color: type == LibraryPlaylistType.actor
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : null,
              ),
              child: type == LibraryPlaylistType.actor && photo != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        photo!.toString(),
                        width: 75,
                        height: 75,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: _getIcon(),
                        ),
                      ),
                    )
                  : Center(
                      child: _getIcon(),
                    ),
            ),
            const SizedBox(width: 16),
            // Titre et informations
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ) ??
                        const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Pour les artistes, ne pas afficher le compteur d'éléments
                  if (type != LibraryPlaylistType.actor) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (isPinned) ...[
                          const Icon(
                            Icons.push_pin,
                            size: 20,
                            color: Color(0xFF5493DE),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          '$itemCount ${itemCount == 1 ? 'élément' : 'éléments'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ) ??
                              const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
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

