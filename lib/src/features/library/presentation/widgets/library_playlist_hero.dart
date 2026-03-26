import 'package:flutter/material.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/widgets/movi_hero_background.dart';
import 'package:movi/src/core/widgets/movi_pill.dart';
import 'package:movi/src/core/widgets/movi_placeholder_card.dart';
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
    required this.horizontalPadding,
    required this.isLargeScreen,
    this.backdrop,
    this.actions,
    this.onMore,
  });

  final LibraryPlaylistItem playlist;
  final int itemCount;
  final Color accentColor;
  final VoidCallback onBack;
  final double horizontalPadding;
  final bool isLargeScreen;
  final String? backdrop;
  final Widget? actions;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    if (isLargeScreen) {
      final cs = Theme.of(context).colorScheme;
      return SizedBox(
        height: 500,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MoviHeroBackground(
              poster: playlist.photo?.toString(),
              backdrop: backdrop,
              placeholderType: _placeholderType(),
              imageStrategy: MoviHeroImageStrategy.backdropFirst,
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        cs.surface,
                        cs.surface.withValues(alpha: 0.72),
                        cs.surface.withValues(alpha: 0),
                      ],
                      stops: const [0.0, 0.4, 0.82],
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: _TopOverlay(height: 132),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomOverlay(height: 200),
            ),
            Positioned(
              top: 12,
              left: horizontalPadding,
              right: horizontalPadding,
              child: _HeroTopBar(
                onBack: onBack,
                onMore: onMore,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          MoviPill(_typeLabel(context), large: true),
                          MoviPill(_countLabel(context), large: true),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        playlist.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.0,
                            ) ??
                            const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                              color: Colors.white,
                            ),
                      ),
                      if (actions != null) ...[
                        const SizedBox(height: 20),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 340),
                          child: actions!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

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

  PlaceholderType _placeholderType() {
    if (playlist.type == LibraryPlaylistType.actor) {
      return PlaceholderType.person;
    }
    if (playlist.type == LibraryPlaylistType.favoriteSeries) {
      return PlaceholderType.series;
    }
    return PlaceholderType.movie;
  }

  String _typeLabel(BuildContext context) {
    switch (playlist.type) {
      case LibraryPlaylistType.inProgress:
        return 'En cours';
      case LibraryPlaylistType.favoriteMovies:
        return 'Films favoris';
      case LibraryPlaylistType.favoriteSeries:
        return 'Séries favorites';
      case LibraryPlaylistType.watchHistory:
        return 'Historique';
      case LibraryPlaylistType.userPlaylist:
        return 'Playlist';
      case LibraryPlaylistType.actor:
        return 'Artiste';
    }
  }

  String _countLabel(BuildContext context) {
    return itemCount == 1
        ? AppLocalizations.of(context)!.libraryItemCount(itemCount)
        : AppLocalizations.of(context)!.libraryItemCountPlural(itemCount);
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

class _HeroTopBar extends StatelessWidget {
  const _HeroTopBar({
    required this.onBack,
    required this.onMore,
  });

  final VoidCallback onBack;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onBack,
          child: const SizedBox(
            width: 35,
            height: 35,
            child: Image(image: AssetImage(AppAssets.iconBack)),
          ),
        ),
        if (onMore != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onMore,
            child: const SizedBox(
              width: 25,
              height: 35,
              child: Image(image: AssetImage(AppAssets.iconMore)),
            ),
          )
        else
          const SizedBox(width: 25, height: 35),
      ],
    );
  }
}

class _TopOverlay extends StatelessWidget {
  const _TopOverlay({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF141414), Color(0x00000000)],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomOverlay extends StatelessWidget {
  const _BottomOverlay({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xFF141414), Color(0x00000000)],
            ),
          ),
        ),
      ),
    );
  }
}
