import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/cupertino.dart';

import 'package:movi/src/core/utils/navigation_helpers.dart';
import 'package:movi/src/shared/presentation/router/content_route_args.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/features/library/presentation/widgets/library_playlist_card.dart';
import 'package:movi/src/features/library/presentation/widgets/library_playlist_hero.dart';
import 'package:movi/src/features/library/presentation/widgets/library_playlist_actions_bar.dart';
import 'package:movi/src/features/playlist/playlist.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/features/library/domain/services/library_playlist_sorter.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/shared/domain/services/iptv_content_resolver.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart';
import 'package:movi/src/features/movie/presentation/providers/movie_detail_providers.dart';
import 'package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart';

// Enum déplacé dans le domaine: LibraryPlaylistSortType

class LibraryPlaylistDetailPage extends ConsumerStatefulWidget {
  const LibraryPlaylistDetailPage({super.key, required this.playlist});

  final LibraryPlaylistItem playlist;

  @override
  ConsumerState<LibraryPlaylistDetailPage> createState() =>
      _LibraryPlaylistDetailPageState();
}

class _LibraryPlaylistDetailPageState
    extends ConsumerState<LibraryPlaylistDetailPage> {
  LibraryPlaylistSortType? _sortType;

  /// Provider pour les playlists non-utilisateur (favoris, historique, etc.)
  static final _otherPlaylistItemsProvider =
      FutureProvider.family<List<ContentReference>, LibraryPlaylistItem>((
        ref,
        playlist,
      ) async {
        final repository = ref.watch(libraryRepositoryProvider);

        switch (playlist.type) {
          case LibraryPlaylistType.inProgress:
            return await repository.getHistoryInProgress();
          case LibraryPlaylistType.favoriteMovies:
            final movies = await repository.getLikedMovies();
            return movies
                .map(
                  (m) => ContentReference(
                    id: m.id.value,
                    title: m.title,
                    type: ContentType.movie,
                    poster: m.poster,
                    year: m.releaseYear,
                  ),
                )
                .toList();
          case LibraryPlaylistType.favoriteSeries:
            final series = await repository.getLikedShows();
            return series
                .map(
                  (s) => ContentReference(
                    id: s.id.value,
                    title: s.title,
                    type: ContentType.series,
                    poster: s.poster,
                  ),
                )
                .toList();
          case LibraryPlaylistType.watchHistory:
            final completed = await repository.getHistoryCompleted();
            final inProgress = await repository.getHistoryInProgress();
            return [...completed, ...inProgress];
          case LibraryPlaylistType.userPlaylist:
          case LibraryPlaylistType.actor:
            return [];
        }
      });

  void _showSortMenu(BuildContext context, WidgetRef ref) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(AppLocalizations.of(context)!.playlistSortByTitle),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) {
                setState(() {
                  _sortType = LibraryPlaylistSortType.title;
                });
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppLocalizations.of(context)!.playlistSortByTitleOption),
                if (_sortType == LibraryPlaylistSortType.title)
                  const SizedBox(width: 8),
                if (_sortType == LibraryPlaylistSortType.title)
                  const Icon(Icons.check, size: 20),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) {
                setState(() {
                  _sortType = LibraryPlaylistSortType.recentlyAdded;
                });
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppLocalizations.of(context)!.playlistSortRecentAdditions),
                if (_sortType == LibraryPlaylistSortType.recentlyAdded)
                  const SizedBox(width: 8),
                if (_sortType == LibraryPlaylistSortType.recentlyAdded)
                  const Icon(Icons.check, size: 20),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) {
                setState(() {
                  _sortType = LibraryPlaylistSortType.yearAscending;
                });
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppLocalizations.of(context)!.playlistSortOldestFirst),
                if (_sortType == LibraryPlaylistSortType.yearAscending)
                  const SizedBox(width: 8),
                if (_sortType == LibraryPlaylistSortType.yearAscending)
                  const Icon(Icons.check, size: 20),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) {
                setState(() {
                  _sortType = LibraryPlaylistSortType.yearDescending;
                });
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppLocalizations.of(context)!.playlistSortNewestFirst),
                if (_sortType == LibraryPlaylistSortType.yearDescending)
                  const SizedBox(width: 8),
                if (_sortType == LibraryPlaylistSortType.yearDescending)
                  const Icon(Icons.check, size: 20),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(AppLocalizations.of(context)!.actionCancel),
        ),
      ),
    );
  }

  void _playRandomly(BuildContext context, List<ContentReference> items) {
    if (items.isEmpty) return;
    items.shuffle();
    final firstItem = items.first;
    // Pour l'instant, ouvrir le premier élément
    unawaited(_openMedia(context, firstItem));
  }

  void _showPlaylistMenu(BuildContext context, WidgetRef ref) {
    if (widget.playlist.playlistId == null) return;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        return CupertinoActionSheet(
          title: Text(widget.playlist.title),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                _showRenameDialog(context, ref);
              },
              child: Text(AppLocalizations.of(context)!.playlistRenameTitle),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(ctx).pop();
                _showDeleteDialog(context, ref);
              },
              child: Text(AppLocalizations.of(context)!.playlistDeleteTitle),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.actionCancel),
          ),
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    if (widget.playlist.playlistId == null) return;

    final nameController = TextEditingController(text: widget.playlist.title);

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(AppLocalizations.of(context)!.playlistRenameTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: nameController,
            placeholder: AppLocalizations.of(context)!.playlistNamePlaceholder,
            autofocus: true,
            padding: const EdgeInsets.all(12),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.actionCancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                Navigator.of(ctx).pop();
                return;
              }

              Navigator.of(ctx).pop();

              try {
                final renamePlaylist = ref.read(renamePlaylistUseCaseProvider);

                await renamePlaylist(
                  id: PlaylistId(widget.playlist.playlistId!),
                  title: MediaTitle(name),
                );

                ref.invalidate(libraryPlaylistsProvider);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(
                          context,
                        )!.playlistRenamedSuccess(name),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.actionConfirm),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    if (widget.playlist.playlistId == null) return;

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(AppLocalizations.of(context)!.playlistDeleteTitle),
        content: Text(
          AppLocalizations.of(
            context,
          )!.playlistDeleteConfirm(widget.playlist.title),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.actionCancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(ctx).pop();

              try {
                final deletePlaylist = ref.read(deletePlaylistUseCaseProvider);

                await deletePlaylist(PlaylistId(widget.playlist.playlistId!));

                ref.invalidate(libraryPlaylistsProvider);

                if (context.mounted) {
                  context.pop(); // Retourner à la bibliothèque
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.playlistDeletedSuccess,
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.playlistDeleteTitle),
          ),
        ],
      ),
    );
  }

  Future<void> _openMedia(
    BuildContext context,
    ContentReference reference,
  ) async {
    final locator = ref.read(slProvider);
    final resolver = locator<IptvContentResolver>();
    final activeSourceIds =
        ref.read(asp.appStateControllerProvider).preferredIptvSourceIds;
    final resolution = await resolver.resolve(
      contentId: reference.id,
      type: reference.type,
      activeSourceIds: activeSourceIds,
    );
    if (!context.mounted) return;
    if (!resolution.isAvailable || resolution.resolvedContentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pas disponible sur cette source')),
      );
      return;
    }

    final resolvedId = resolution.resolvedContentId!;
    if (reference.type == ContentType.movie) {
      navigateToMovieDetail(context, ref, ContentRouteArgs.movie(resolvedId));
    } else {
      navigateToTvDetail(context, ref, ContentRouteArgs.series(resolvedId));
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = ref.watch(asp.currentAccentColorProvider);
    // Pour les playlists utilisateur, utiliser le provider pour permettre l'invalidation
    final itemsAsync =
        widget.playlist.type == LibraryPlaylistType.userPlaylist &&
            widget.playlist.playlistId != null
        ? ref.watch(
            playlistContentReferencesProvider(widget.playlist.playlistId!),
          )
        : ref.watch(_otherPlaylistItemsProvider(widget.playlist));

    // Pour les playlists utilisateur, récupérer aussi les items complets avec positions
    final playlistItemsAsync =
        widget.playlist.type == LibraryPlaylistType.userPlaylist &&
            widget.playlist.playlistId != null
        ? ref.watch(playlistItemsProvider(widget.playlist.playlistId!))
        : null;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // Hero section (350px)
            itemsAsync.when(
              loading: () => const SizedBox(height: 350),
              error: (error, stackTrace) {
                // Afficher l'erreur pour le débogage
                return SizedBox(
                  height: 350,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.white70,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur: $error',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
              data: (items) => LibraryPlaylistHero(
                playlist: widget.playlist,
                accentColor: accentColor,
                itemCount: items.length,
                onBack: () => context.pop(),
                onMore: widget.playlist.type == LibraryPlaylistType.userPlaylist
                    ? () => _showPlaylistMenu(context, ref)
                    : null,
              ),
            ),
            // Boutons d'action (collés sous le hero)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: itemsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (items) {
                  final isEmpty = items.isEmpty;
                  // Pour les playlists utilisateur, récupérer les items complets pour le tri
                  final playlistItems = playlistItemsAsync?.value;
                  final sortedItems = LibraryPlaylistSorter.sort(
                    items,
                    sortType: _sortType,
                    playlistItems: playlistItems,
                  );

                  return LibraryPlaylistActionsBar(
                    isEmpty: isEmpty,
                    onPlayRandom: isEmpty
                        ? null
                        : () => _playRandomly(context, sortedItems),
                    onSortPressed: isEmpty
                        ? null
                        : () => _showSortMenu(context, ref),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            // Liste des médias
            Expanded(
              child: itemsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.white70,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur de chargement',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        AppLocalizations.of(context)!.playlistEmptyMessage,
                        style:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white70,
                            ) ??
                            const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                      ),
                    );
                  }

                  // Pour les playlists utilisateur, récupérer les items complets pour le tri
                  final playlistItems = playlistItemsAsync?.value;
                  final sortedItems = LibraryPlaylistSorter.sort(
                    items,
                    sortType: _sortType,
                    playlistItems: playlistItems,
                  );

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: sortedItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = sortedItems[index];
                      // Pour les playlists utilisateur, récupérer l'item complet avec position
                      if (widget.playlist.type ==
                              LibraryPlaylistType.userPlaylist &&
                          widget.playlist.playlistId != null &&
                          playlistItemsAsync != null) {
                        return playlistItemsAsync.when(
                          loading: () => _buildMediaItem(context, ref, item),
                          error: (_, __) => _buildMediaItem(context, ref, item),
                          data: (playlistItems) {
                            final playlistItem = playlistItems.firstWhere(
                              (pi) => pi.reference.id == item.id,
                              orElse: () => PlaylistItem(reference: item),
                            );
                            return _buildMediaItem(
                              context,
                              ref,
                              item,
                              playlistItem: playlistItem,
                              playlistId: widget.playlist.playlistId,
                            );
                          },
                        );
                      }
                      return _buildMediaItem(context, ref, item);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaItem(
    BuildContext context,
    WidgetRef ref,
    ContentReference reference, {
    PlaylistItem? playlistItem,
    String? playlistId,
  }) {
    // Utiliser le provider pour charger le backdrop
    final backdropAsync = ref.watch(playlistItemBackdropProvider(reference));
    final mediaInfoAsync = Future.value(_getMediaInfo(ref, reference));

    return FutureBuilder<({Duration? duration, int? seasonCount})>(
      future: mediaInfoAsync,
      builder: (context, snapshot) {
        final duration = snapshot.data?.duration;
        final seasonCount = snapshot.data?.seasonCount;

        // Permettre la suppression pour les playlists utilisateur, favoris, en cours et historique
        final canDelete =
            (widget.playlist.type == LibraryPlaylistType.userPlaylist &&
                playlistId != null &&
                playlistItem != null &&
                playlistItem.position != null) ||
            widget.playlist.type == LibraryPlaylistType.favoriteMovies ||
            widget.playlist.type == LibraryPlaylistType.favoriteSeries ||
            widget.playlist.type == LibraryPlaylistType.inProgress ||
            widget.playlist.type == LibraryPlaylistType.watchHistory;

        Widget content = GestureDetector(
          onTap: () => unawaited(_openMedia(context, reference)),
          onLongPress: canDelete
              ? () {
                  if (widget.playlist.type == LibraryPlaylistType.userPlaylist &&
                      playlistItem != null &&
                      playlistId != null) {
                    _showDeleteItemDialog(
                      context,
                      ref,
                      reference,
                      playlistItem,
                      playlistId,
                    );
                  } else {
                    _showDeleteOtherItemDialog(context, ref, reference);
                  }
                }
              : null,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Backdrop paysage (180x100)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: backdropAsync.when(
                    loading: () => Container(
                      width: 180,
                      height: 100,
                      color: const Color(0xFF222222),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                    error: (_, __) => Container(
                      width: 180,
                      height: 100,
                      color: const Color(0xFF222222),
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 32,
                      ),
                    ),
                    data: (backdropUri) {
                      if (backdropUri != null) {
                        return Image.network(
                          backdropUri.toString(),
                          width: 180,
                          height: 100,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 180,
                              height: 100,
                              color: const Color(0xFF222222),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  color: Colors.white54,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 180,
                              height: 100,
                              color: const Color(0xFF222222),
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.white54,
                                size: 32,
                              ),
                            );
                          },
                        );
                      }
                      return Container(
                        width: 180,
                        height: 100,
                        color: const Color(0xFF222222),
                        child: const Icon(
                          Icons.movie,
                          color: Colors.white54,
                          size: 32,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Informations
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Titre avec bouton more
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              reference.title.value,
                              style:
                                  Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                          ),
                          if (canDelete) ...[
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                _showItemOptionsMenuGeneric(
                                  context,
                                  ref,
                                  reference,
                                  playlistItem: playlistItem,
                                  playlistId: playlistId,
                                );
                              },
                              child: const Icon(
                                Icons.more_horiz,
                                color: Colors.white70,
                                size: 24,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Pills: année, rating, durée
                      // Utiliser IntrinsicWidth pour que le Row prenne la bonne taille
                      IntrinsicWidth(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Pill avec année
                            if (reference.year != null)
                              MoviPill(
                                reference.year.toString(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                            // Pill avec type de contenu (Série ou Film) pour les playlists utilisateur
                            if (widget.playlist.type ==
                                LibraryPlaylistType.userPlaylist) ...[
                              if (reference.year != null)
                                const SizedBox(width: 8),
                              MoviPill(
                                reference.type == ContentType.series
                                    ? AppLocalizations.of(context)!.serie
                                    : AppLocalizations.of(context)!.moviesTitle,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                            ],
                            // Espace entre année/type et rating
                            if ((reference.year != null ||
                                    (widget.playlist.type ==
                                        LibraryPlaylistType.userPlaylist)) &&
                                reference.rating != null)
                              const SizedBox(width: 8),
                            // Rating pill
                            if (reference.rating != null)
                              MoviPill(
                                reference.rating!.toStringAsFixed(1),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                            // Espace entre rating et durée
                            if (reference.rating != null &&
                                snapshot.connectionState ==
                                    ConnectionState.done &&
                                snapshot.hasData &&
                                ((reference.type == ContentType.movie &&
                                        duration != null) ||
                                    (reference.type == ContentType.series &&
                                        seasonCount != null)))
                              const SizedBox(width: 8),
                            // Durée pill (si les données sont chargées)
                            if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                snapshot.hasData)
                              if (reference.type == ContentType.movie &&
                                  duration != null)
                                MoviPill(
                                  _formatDuration(duration),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                )
                              else if (reference.type == ContentType.series &&
                                  seasonCount != null)
                                MoviPill(
                                  '$seasonCount ${seasonCount == 1 ? AppLocalizations.of(context)!.playlistSeasonSingular : AppLocalizations.of(context)!.playlistSeasonPlural}',
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

        // Envelopper dans Dismissible pour swipe vers la gauche
        if (canDelete) {
          final dismissibleKey = widget.playlist.type == LibraryPlaylistType.userPlaylist &&
                  playlistId != null &&
                  playlistItem != null &&
                  playlistItem.position != null
              ? Key('${playlistId}_${reference.id}_${playlistItem.position}')
              : Key('${widget.playlist.type}_${reference.id}');
          
          return Dismissible(
            key: dismissibleKey,
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete, color: Colors.white, size: 32),
            ),
            onDismissed: (direction) {
              if (widget.playlist.type == LibraryPlaylistType.userPlaylist &&
                  playlistItem != null &&
                  playlistId != null) {
                _removeItemFromPlaylist(context, ref, playlistItem, playlistId);
              } else {
                _removeOtherItem(context, ref, reference);
              }
            },
            child: content,
          );
        }

        return content;
      },
    );
  }

  void _showDeleteItemDialog(
    BuildContext context,
    WidgetRef ref,
    ContentReference reference,
    PlaylistItem playlistItem,
    String playlistId,
  ) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(AppLocalizations.of(context)!.playlistDeleteTitle),
        content: Text(
          AppLocalizations.of(
            context,
          )!.playlistRemoveItemConfirm(reference.title.value),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.actionCancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              _removeItemFromPlaylist(context, ref, playlistItem, playlistId);
            },
            child: Text(AppLocalizations.of(context)!.playlistDeleteTitle),
          ),
        ],
      ),
    );
  }

  Future<void> _removeItemFromPlaylist(
    BuildContext context,
    WidgetRef ref,
    PlaylistItem playlistItem,
    String playlistId,
  ) async {
    try {
      final removePlaylistItem = ref.read(removePlaylistItemUseCaseProvider);

      await removePlaylistItem(
        playlistId: PlaylistId(playlistId),
        item: playlistItem,
      );

      // Invalider les providers pour rafraîchir
      ref.invalidate(playlistItemsProvider(playlistId));
      ref.invalidate(playlistContentReferencesProvider(playlistId));
      ref.invalidate(libraryPlaylistsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.playlistItemRemovedSuccess,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  /// Menu générique pour les options d'un élément de playlist
  /// Gère à la fois les playlists utilisateur et les autres types (favoris, en cours, historique)
  void _showItemOptionsMenuGeneric(
    BuildContext context,
    WidgetRef ref,
    ContentReference reference, {
    PlaylistItem? playlistItem,
    String? playlistId,
  }) {
    // Si c'est une playlist utilisateur avec les paramètres nécessaires, utiliser la méthode existante
    if (playlistItem != null && playlistId != null) {
      _showItemOptionsMenu(
        context,
        ref,
        reference,
        playlistItem,
        playlistId,
      );
      return;
    }

    // Pour les autres types de playlists (favoris, en cours, historique)
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(reference.title.value),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              _showDeleteOtherItemDialog(context, ref, reference);
            },
            child: Text(AppLocalizations.of(context)!.playlistDeleteTitle),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showAddItemToPlaylistDialog(context, ref, reference);
            },
            child: Text(AppLocalizations.of(context)!.actionAddToList),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(AppLocalizations.of(context)!.actionCancel),
        ),
      ),
    );
  }

  void _showItemOptionsMenu(
    BuildContext context,
    WidgetRef ref,
    ContentReference reference,
    PlaylistItem playlistItem,
    String playlistId,
  ) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(reference.title.value),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              _showDeleteItemDialog(
                context,
                ref,
                reference,
                playlistItem,
                playlistId,
              );
            },
            child: Text(AppLocalizations.of(context)!.playlistDeleteTitle),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showAddItemToPlaylistDialog(context, ref, reference);
            },
            child: Text(AppLocalizations.of(context)!.actionAddToList),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(AppLocalizations.of(context)!.actionCancel),
        ),
      ),
    );
  }

  Future<void> _showAddItemToPlaylistDialog(
    BuildContext context,
    WidgetRef ref,
    ContentReference reference,
  ) async {
    try {
      // Utiliser ref.read au lieu de ref.watch pour éviter les rebuilds en boucle
      final playlistsAsync = ref.read(libraryPlaylistsProvider);

      return playlistsAsync.when(
        loading: () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chargement des playlists...')),
            );
          }
        },
        error: (error, stackTrace) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur lors du chargement: $error')),
            );
          }
        },
        data: (playlists) async {
          if (playlists.isEmpty) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.movieNoPlaylistsAvailable,
                  ),
                ),
              );
            }
            return;
          }

          // Filtrer les playlists selon le type de contenu
          final availablePlaylists = <LibraryPlaylistItem>[];

          for (final playlist in playlists) {
            // Exclure la playlist actuelle
            if (playlist.playlistId == widget.playlist.playlistId) {
              continue;
            }

            // Exclure les sagas et acteurs
            if (playlist.id.startsWith('saga_') ||
                playlist.type == LibraryPlaylistType.actor) {
              continue;
            }

            // Exclure les playlists favorites (non pertinentes pour ajouter depuis une playlist)
            if (playlist.type == LibraryPlaylistType.favoriteMovies ||
                playlist.type == LibraryPlaylistType.favoriteSeries ||
                playlist.type == LibraryPlaylistType.inProgress ||
                playlist.type == LibraryPlaylistType.watchHistory) {
              continue;
            }

            // Playlists utilisateur : permettre les playlists mixtes
            if (playlist.type == LibraryPlaylistType.userPlaylist &&
                playlist.playlistId != null) {
              availablePlaylists.add(playlist);
            }
          }

          if (!mounted || !context.mounted) return;
          if (availablePlaylists.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.movieNoPlaylistsAvailable,
                ),
              ),
            );
            return;
          }

          // Capturer ref avant d'ouvrir le dialogue pour éviter les problèmes de scope
          final refForDialog = ref;

          showCupertinoModalPopup<void>(
            context: context,
            builder: (ctx) {
              return CupertinoActionSheet(
                title: Text(AppLocalizations.of(context)!.actionAddToList),
                actions: availablePlaylists.map((playlist) {
                  return CupertinoActionSheetAction(
                    onPressed: () async {
                      Navigator.of(ctx).pop();

                      // Capturer toutes les dépendances AVANT les opérations asynchrones
                      final logger = refForDialog.read(slProvider)<AppLogger>();
                      final playlistIdToInvalidate = playlist.playlistId;

                      try {
                        // Ajouter à la playlist utilisateur
                        final addPlaylistItem = refForDialog.read(
                          addPlaylistItemUseCaseProvider,
                        );

                        await addPlaylistItem.call(
                          playlistId: PlaylistId(playlist.playlistId!),
                          item: PlaylistItem(
                            reference: reference,
                            addedAt: DateTime.now(),
                          ),
                        );

                        // Vérifier que le widget est encore monté avant d'utiliser ref
                        if (!mounted || !context.mounted) return;
                        // Invalider tous les providers nécessaires
                        // Note: Ces invalidations ne causeront pas de rebuild du dialogue
                        // car nous utilisons ref.read au lieu de ref.watch
                        refForDialog.invalidate(
                          playlistItemsProvider(playlistIdToInvalidate!),
                        );
                        refForDialog.invalidate(
                          playlistContentReferencesProvider(
                            playlistIdToInvalidate,
                          ),
                        );
                        refForDialog.invalidate(libraryPlaylistsProvider);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.playlistAddedTo(playlist.title),
                                ),
                              ),
                            );
                          }
                        } catch (e, stackTrace) {
                          // Logger l'erreur pour le debug
                          logger.log(
                            LogLevel.error,
                            'Erreur lors de l\'ajout à la playlist: $e',
                            error: e,
                            stackTrace: stackTrace,
                            category: 'library_playlist_detail',
                          );

                          if (context.mounted) {
                            // Gérer spécifiquement l'erreur de doublon
                            String errorMessage;
                            if (e is StateError &&
                                e.message.contains(
                                  'déjà dans cette playlist',
                                )) {
                              errorMessage =
                                  'Ce média est déjà dans cette playlist';
                            } else {
                              errorMessage = AppLocalizations.of(
                                context,
                              )!.errorWithMessage(e.toString());
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                        }
                      },
                      child: Text(playlist.title),
                    );
                  }).toList(),
                cancelButton: CupertinoActionSheetAction(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(AppLocalizations.of(context)!.actionCancel),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des playlists: $e'),
          ),
        );
      }
    }
  }

  void _showDeleteOtherItemDialog(
    BuildContext context,
    WidgetRef ref,
    ContentReference reference,
  ) {
    final l10n = AppLocalizations.of(context)!;
    String title;
    switch (widget.playlist.type) {
      case LibraryPlaylistType.favoriteMovies:
      case LibraryPlaylistType.favoriteSeries:
        title = l10n.playlistDeleteTitle; // Utiliser le titre de suppression existant
        break;
      case LibraryPlaylistType.inProgress:
        title = l10n.playlistDeleteTitle;
        break;
      case LibraryPlaylistType.watchHistory:
        title = l10n.playlistDeleteTitle;
        break;
      default:
        title = l10n.playlistDeleteTitle;
    }

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(
          AppLocalizations.of(
            context,
          )!.playlistRemoveItemConfirm(reference.title.value),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.actionCancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              _removeOtherItem(context, ref, reference);
            },
            child: Text(AppLocalizations.of(context)!.playlistDeleteTitle),
          ),
        ],
      ),
    );
  }

  Future<void> _removeOtherItem(
    BuildContext context,
    WidgetRef ref,
    ContentReference reference,
  ) async {
    try {
      final locator = ref.read(slProvider);
      final userId = ref.read(currentUserIdProvider);

      switch (widget.playlist.type) {
        case LibraryPlaylistType.favoriteMovies:
        case LibraryPlaylistType.favoriteSeries:
          final watchlist = locator<WatchlistLocalRepository>();
          await watchlist.remove(
            reference.id,
            reference.type,
            userId: userId,
          );
          break;
        case LibraryPlaylistType.inProgress:
          // La playlist "en cours" est basée sur l'historique, donc il faut supprimer de l'historique
          final history = locator<HistoryLocalRepository>();
          await history.remove(
            reference.id,
            reference.type,
            userId: userId,
          );
          // Supprimer aussi de continue_watching si présent (pour la section Home)
          final continueWatching = locator<ContinueWatchingLocalRepository>();
          final continueWatchingEntries = await continueWatching.readAll(
            reference.type,
            userId: userId,
          );
          final isInContinueWatching = continueWatchingEntries.any(
            (entry) => entry.contentId == reference.id,
          );
          if (isInContinueWatching) {
            await continueWatching.remove(
              reference.id,
              reference.type,
              userId: userId,
            );
          }
          break;
        case LibraryPlaylistType.watchHistory:
          final history = locator<HistoryLocalRepository>();
          final continueWatching = locator<ContinueWatchingLocalRepository>();
          
          // Vérifier si le média est dans "en cours"
          final continueWatchingEntries = await continueWatching.readAll(
            reference.type,
            userId: userId,
          );
          final isInProgress = continueWatchingEntries.any(
            (entry) => entry.contentId == reference.id,
          );
          
          // Supprimer de l'historique
          await history.remove(
            reference.id,
            reference.type,
            userId: userId,
          );
          
          // Si aussi dans "en cours", supprimer de là aussi
          if (isInProgress) {
            await continueWatching.remove(
              reference.id,
              reference.type,
              userId: userId,
            );
          }
          break;
        default:
          return;
      }

      // Invalider les providers pour rafraîchir
      ref.invalidate(_otherPlaylistItemsProvider(widget.playlist));
      ref.invalidate(libraryPlaylistsProvider);
      
      // Invalider les providers spécifiques selon le type de playlist
      switch (widget.playlist.type) {
        case LibraryPlaylistType.favoriteMovies:
          if (reference.type == ContentType.movie) {
            ref.invalidate(movieIsFavoriteProvider(reference.id));
          }
          break;
        case LibraryPlaylistType.favoriteSeries:
          if (reference.type == ContentType.series) {
            ref.invalidate(tvIsFavoriteProvider(reference.id));
          }
          break;
        case LibraryPlaylistType.inProgress:
          ref.invalidate(homeInProgressProvider);
          break;
        case LibraryPlaylistType.watchHistory:
          // Invalider les providers d'historique si nécessaire
          ref.invalidate(homeInProgressProvider);
          break;
        default:
          break;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.playlistItemRemovedSuccess,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<({Duration? duration, int? seasonCount})> _getMediaInfo(
    WidgetRef ref,
    ContentReference reference,
  ) async {
    if (reference.type == ContentType.movie) {
      // MovieSummary n'a pas de durée, on retourne null pour l'instant

      return (duration: null, seasonCount: null);
    } else if (reference.type == ContentType.series) {
      // Pour les séries, récupérer le nombre de saisons
      try {
        final repository = ref.read(libraryRepositoryProvider);
        final series = await repository.getLikedShows();
        final show = series.firstWhere(
          (s) => s.id.value == reference.id,
          orElse: () => throw Exception('Show not found'),
        );
        return (duration: null, seasonCount: show.seasonCount);
      } catch (_) {
        // Ignorer les erreurs
      }
      return (duration: null, seasonCount: null);
    }
    return (duration: null, seasonCount: null);
  }
}
