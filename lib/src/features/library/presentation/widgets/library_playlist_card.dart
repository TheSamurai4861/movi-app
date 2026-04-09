import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/l10n/app_localizations.dart';
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
    this.isSaga = false,
    this.showItemCount =
        true, // Par défaut afficher le compteur, sauf pour les sagas
    this.layout = LibraryPlaylistCardLayout.horizontal,
    this.focusNode,
    this.autofocus = false,
    this.onMorePressed,
  });

  final String title;
  final int itemCount;
  final LibraryPlaylistType type;
  final bool isPinned;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Uri?
  photo; // Photo de profil pour les artistes ou image hero pour les sagas
  final bool isSaga;
  final bool showItemCount; // Contrôle l'affichage du compteur d'éléments
  final LibraryPlaylistCardLayout layout;
  final FocusNode? focusNode;
  final bool autofocus;
  final VoidCallback? onMorePressed;

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
        return const MoviAssetIcon(
          AppAssets.iconPlaylist,
          width: 40,
          height: 40,
          color: Colors.white,
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

  String _typeLabel(AppLocalizations? l10n) {
    if (isSaga) return l10n?.libraryTypeSaga ?? 'Saga';
    switch (type) {
      case LibraryPlaylistType.inProgress:
        return l10n?.libraryTypeInProgress ?? 'En cours';
      case LibraryPlaylistType.favoriteMovies:
        return l10n?.libraryTypeFavoriteMovies ?? 'Films favoris';
      case LibraryPlaylistType.favoriteSeries:
        return l10n?.libraryTypeFavoriteSeries ?? 'Séries favorites';
      case LibraryPlaylistType.watchHistory:
        return l10n?.libraryTypeHistory ?? 'Historique';
      case LibraryPlaylistType.userPlaylist:
        return l10n?.libraryTypePlaylist ?? 'Playlist';
      case LibraryPlaylistType.actor:
        return l10n?.libraryTypeArtist ?? 'Artiste';
    }
  }

  String _secondaryText(AppLocalizations? l10n) {
    final typeLabel = _typeLabel(l10n);
    final showCount = showItemCount && type != LibraryPlaylistType.actor;
    if (!showCount) return typeLabel;
    final countLabel = l10n?.libraryItemCount(itemCount) ?? '$itemCount';
    return '$typeLabel - $countLabel';
  }

  double _artworkSizeForVertical(double maxWidth) {
    // Desktop: artwork smaller for better density and focus navigation.
    // Keep it stable so the grid looks aligned.
    final base = (maxWidth - 8).clamp(0.0, 220.0);
    return base.clamp(0.0, 160.0);
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
      border: isFocused ? Border.all(color: accentColor, width: 2) : null,
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

  Widget _buildMoreButton(BuildContext context, AppLocalizations? l10n) {
    return SizedBox(
      width: 44,
      height: 44,
      child: MoviFocusableAction(
        onPressed: onMorePressed,
        semanticLabel: l10n?.hc_plus_d_actions_ffe6be2a ?? 'Plus d\'actions',
        builder: (context, state) {
          final backgroundColor = state.focused
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.08);
          return MoviFocusFrame(
            scale: state.focused ? 1.04 : 1,
            padding: const EdgeInsets.all(10),
            borderRadius: BorderRadius.circular(999),
            backgroundColor: backgroundColor,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: MoviAssetIcon(AppAssets.iconMore, color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(asp.currentAccentColorProvider);
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
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
              final imageSize = _artworkSizeForVertical(constraints.maxWidth);
              return MoviFocusFrame(
                scale: state.focused ? 1.02 : 1,
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
                      _secondaryText(l10n),
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: MoviFocusableAction(
              onPressed: onTap,
              onLongPress: onLongPress,
              focusNode: focusNode,
              autofocus: autofocus,
              semanticLabel: title,
              builder: (context, state) {
                return MoviFocusFrame(
                  scale: state.focused ? 1.02 : 1,
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 75,
                        height: 75,
                        child: _buildArtwork(
                          context,
                          accentColor,
                          width: 75,
                          height: 75,
                          borderRadius: 16,
                          isFocused: state.focused,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style:
                                  Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.copyWith(
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
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: _secondaryText(l10n)),
                                  if (isPinned)
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: Icon(
                                          Icons.push_pin,
                                          size: 14,
                                          color: accentColor,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              style:
                                  Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
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
                );
              },
            ),
          ),
          if (onMorePressed != null) ...[
            const SizedBox(width: 20),
            _buildMoreButton(context, l10n),
          ],
        ],
      ),
    );
  }
}
