import 'package:flutter/material.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/features/library/presentation/widgets/library_playlist_card.dart';

/// Hero visuel d'une playlist de bibliothèque (gradient, icône, titre, compteur).
class LibraryPlaylistHero extends StatelessWidget {
  const LibraryPlaylistHero({
    super.key,
    required this.playlist,
    required this.itemCount,
    required this.accentColor,
    required this.onBack,
    this.onMore,
  });

  final LibraryPlaylistItem playlist;
  final int itemCount;
  final Color accentColor;
  final VoidCallback onBack;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Gradient de fond diagonal
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accentColor, _darkenColor(accentColor)],
              ),
            ),
          ),
          // Top overlay (100px)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF141414), Color(0x00000000)],
                ),
              ),
            ),
          ),
          // Bottom overlay (150px)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 150,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xFF141414), Color(0x00000000)],
                ),
              ),
            ),
          ),
          // Boutons retour et more (en haut)
          Positioned(
            top: 8,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onBack,
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 35,
                        height: 35,
                        child: Image(image: AssetImage(AppAssets.iconBack)),
                      ),
                    ],
                  ),
                ),
                if (onMore != null)
                  SizedBox(
                    width: 25,
                    height: 35,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onMore,
                      child: const Image(image: AssetImage(AppAssets.iconMore)),
                    ),
                  )
                else
                  const SizedBox(width: 25),
              ],
            ),
          ),
          // Logo centré
          Center(child: _getPlaylistIcon()),
          // Titre
          Positioned(
            bottom: 58,
            left: 0,
            right: 0,
            child: Text(
              playlist.title,
              textAlign: TextAlign.center,
              style:
                  Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ) ??
                  const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
            ),
          ),
          // Nombre d'éléments
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Text(
              itemCount == 1
                  ? AppLocalizations.of(context)!.libraryItemCount(itemCount)
                  : AppLocalizations.of(context)!.libraryItemCountPlural(itemCount),
              textAlign: TextAlign.center,
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ) ??
                  const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// Génère une couleur foncée à partir de l'accent color.
  Color _darkenColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness(0.15.clamp(0.0, 1.0))
        .withSaturation((hsl.saturation * 0.7).clamp(0.0, 1.0))
        .toColor();
  }

  Widget _getPlaylistIcon() {
    switch (playlist.type) {
      case LibraryPlaylistType.inProgress:
        return const Icon(
          Icons.play_circle_outline,
          color: Colors.white,
          size: 64,
        );
      case LibraryPlaylistType.favoriteMovies:
        return const Icon(Icons.local_movies, color: Colors.white, size: 64);
      case LibraryPlaylistType.favoriteSeries:
        return const Icon(Icons.tv, color: Colors.white, size: 64);
      case LibraryPlaylistType.watchHistory:
        return const Icon(Icons.history, color: Colors.white, size: 64);
      case LibraryPlaylistType.userPlaylist:
        return const Icon(Icons.playlist_play, color: Colors.white, size: 64);
      case LibraryPlaylistType.actor:
        return const Icon(Icons.person, color: Colors.white, size: 64);
    }
  }
}
