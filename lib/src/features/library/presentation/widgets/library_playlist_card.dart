import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/core/widgets/movi_placeholder_card.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;

enum LibraryPlaylistCardLayout { horizontal, vertical }

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
    this.layout = LibraryPlaylistCardLayout.horizontal,
    this.focusNode,
    this.autofocus = false,
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
  final LibraryPlaylistCardLayout layout;
  final FocusNode? focusNode;
  final bool autofocus;

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
        return const MoviAssetIcon(
          AppAssets.iconMovie,
          width: 40,
          height: 40,
          color: Colors.white,
        );
      case LibraryPlaylistType.favoriteSeries:
        return const MoviAssetIcon(
          AppAssets.iconSeries,
          width: 40,
          height: 40,
          color: Colors.white,
        );
      case LibraryPlaylistType.watchHistory:
        return const MoviAssetIcon(
          AppAssets.iconForward,
          width: 40,
          height: 40,
          color: Colors.white,
        );
      case LibraryPlaylistType.userPlaylist:
        return const MoviAssetIcon(
          AppAssets.navLibrary,
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

  String _typeLabel() {
    switch (type) {
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

  String _secondaryText() {
    final segments = <String>[_typeLabel()];
    if (showItemCount && type != LibraryPlaylistType.actor) {
      segments.add('$itemCount ${itemCount == 1 ? 'élément' : 'éléments'}');
    }
    if (isPinned) {
      segments.add('Épinglée');
    }
    return segments.join(' • ');
  }

  Widget _buildArtwork(
    BuildContext context,
    Color accentColor, {
    required double width,
    required double height,
    required double borderRadius,
    bool isFocused = false,
  }) {
    final isActor = type == LibraryPlaylistType.actor;
    final decoration = BoxDecoration(
      shape: isActor ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: isActor ? null : BorderRadius.circular(borderRadius),
      gradient: (isActor || photo != null)
          ? null
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accentColor, _darkenColor(accentColor)],
            ),
      color: (isActor || photo != null)
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : null,
      border: isFocused ? Border.all(color: Colors.white, width: 2) : null,
    );

    return Container(
      width: width,
      height: height,
      decoration: decoration,
      child: photo != null
          ? ClipRRect(
              borderRadius: isActor
                  ? BorderRadius.circular(width / 2)
                  : BorderRadius.circular(borderRadius),
              child: Image.network(
                photo!.toString(),
                width: width,
                height: height,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(child: _getIcon()),
              ),
            )
          : Center(child: _getIcon()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(asp.currentAccentColorProvider);
    if (layout == LibraryPlaylistCardLayout.vertical) {
      return MoviFocusableAction(
        onPressed: onTap,
        onLongPress: onLongPress,
        focusNode: focusNode,
        autofocus: autofocus,
        semanticLabel: title,
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final imageSize = (constraints.maxWidth - 8).clamp(0.0, 220.0);
              return MoviFocusFrame(
                scale: state.focused ? 1.03 : 1,
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: imageSize,
                      height: imageSize,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _buildArtwork(
                              context,
                              accentColor,
                              width: imageSize,
                              height: imageSize,
                              borderRadius: type == LibraryPlaylistType.actor
                                  ? imageSize / 2
                                  : 20,
                              isFocused: state.focused,
                            ),
                          ),
                          if (isPinned)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.push_pin,
                                    size: 16,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ) ??
                          const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _secondaryText(),
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            height: 1.25,
                          ) ??
                          TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            height: 1.25,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }

    return MoviFocusableAction(
      onPressed: onTap,
      onLongPress: onLongPress,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: title,
      builder: (context, state) {
        return MoviFocusFrame(
          scale: state.focused ? 1.02 : 1,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                _buildArtwork(
                  context,
                  accentColor,
                  width: 75,
                  height: 75,
                  borderRadius: 16,
                  isFocused: state.focused,
                ),
                const SizedBox(width: 16),
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
                      const SizedBox(height: 4),
                      Text(
                        _secondaryText(),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
