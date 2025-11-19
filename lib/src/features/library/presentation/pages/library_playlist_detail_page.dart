import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/core/utils/utils.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/models/models.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/features/library/presentation/widgets/library_playlist_card.dart';
import 'package:movi/src/features/playlist/playlist.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/features/library/presentation/widgets/add_media_search_modal.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;

enum PlaylistSortType { title, recentlyAdded, yearAscending, yearDescending }

class LibraryPlaylistDetailPage extends ConsumerStatefulWidget {
  const LibraryPlaylistDetailPage({super.key, required this.playlist});

  final LibraryPlaylistItem playlist;

  @override
  ConsumerState<LibraryPlaylistDetailPage> createState() =>
      _LibraryPlaylistDetailPageState();
}

class _LibraryPlaylistDetailPageState
    extends ConsumerState<LibraryPlaylistDetailPage> {
  PlaylistSortType? _sortType;

  List<ContentReference> _sortItems(
    List<ContentReference> items,
    PlaylistSortType? sortType, {
    List<PlaylistItem>? playlistItems,
  }) {
    if (sortType == null) return items;

    final sorted = List<ContentReference>.from(items);

    switch (sortType) {
      case PlaylistSortType.title:
        sorted.sort(
          (a, b) => a.title.value.toLowerCase().compareTo(
            b.title.value.toLowerCase(),
          ),
        );
        break;
      case PlaylistSortType.recentlyAdded:
        // Pour les playlists utilisateur, utiliser la date d'ajout
        if (playlistItems != null && playlistItems.isNotEmpty) {
          sorted.sort((a, b) {
            final itemA = playlistItems.firstWhere(
              (pi) => pi.reference.id == a.id,
              orElse: () => PlaylistItem(reference: a),
            );
            final itemB = playlistItems.firstWhere(
              (pi) => pi.reference.id == b.id,
              orElse: () => PlaylistItem(reference: b),
            );
            final dateA = itemA.addedAt ?? DateTime(1970);
            final dateB = itemB.addedAt ?? DateTime(1970);
            // Plus récent en premier
            return dateB.compareTo(dateA);
          });
        }
        // Pour les autres playlists, garder l'ordre original
        break;
      case PlaylistSortType.yearAscending:
        // Séparer les items avec année et sans année
        final withYear = <ContentReference>[];
        final withoutYear = <ContentReference>[];
        
        for (final item in sorted) {
          if (item.year != null) {
            withYear.add(item);
          } else {
            withoutYear.add(item);
          }
        }
        
        // Trier les items avec année de la plus petite à la plus grande
        withYear.sort((a, b) {
          final yearA = a.year ?? 0;
          final yearB = b.year ?? 0;
          return yearA.compareTo(yearB);
        });
        
        // Placer les items sans année à la fin
        return [...withYear, ...withoutYear];
      case PlaylistSortType.yearDescending:
        sorted.sort((a, b) {
          final yearA = a.year ?? 0;
          final yearB = b.year ?? 0;
          return yearB.compareTo(yearA);
        });
        break;
    }

    return sorted;
  }

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
                  _sortType = PlaylistSortType.title;
                });
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppLocalizations.of(context)!.playlistSortByTitleOption),
                if (_sortType == PlaylistSortType.title)
                  const SizedBox(width: 8),
                if (_sortType == PlaylistSortType.title)
                  const Icon(Icons.check, size: 20),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) {
                setState(() {
                  _sortType = PlaylistSortType.recentlyAdded;
                });
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppLocalizations.of(context)!.playlistSortRecentAdditions),
                if (_sortType == PlaylistSortType.recentlyAdded)
                  const SizedBox(width: 8),
                if (_sortType == PlaylistSortType.recentlyAdded)
                  const Icon(Icons.check, size: 20),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) {
                setState(() {
                  _sortType = PlaylistSortType.yearAscending;
                });
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppLocalizations.of(context)!.playlistSortOldestFirst),
                if (_sortType == PlaylistSortType.yearAscending)
                  const SizedBox(width: 8),
                if (_sortType == PlaylistSortType.yearAscending)
                  const Icon(Icons.check, size: 20),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) {
                setState(() {
                  _sortType = PlaylistSortType.yearDescending;
                });
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppLocalizations.of(context)!.playlistSortNewestFirst),
                if (_sortType == PlaylistSortType.yearDescending)
                  const SizedBox(width: 8),
                if (_sortType == PlaylistSortType.yearDescending)
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
    _openMedia(context, firstItem);
  }

  void _showPlaylistMenu(BuildContext context, WidgetRef ref) {
    if (widget.playlist.playlistId == null) return;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
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
      ),
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
                final renamePlaylist = RenamePlaylist(
                  ref.read(slProvider)<PlaylistRepository>(),
                );

                await renamePlaylist.call(
                  id: PlaylistId(widget.playlist.playlistId!),
                  title: MediaTitle(name),
                );

                ref.invalidate(libraryPlaylistsProvider);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.playlistRenamedSuccess(name))),
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
          AppLocalizations.of(context)!.playlistDeleteConfirm(widget.playlist.title),
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
                final deletePlaylist = DeletePlaylist(
                  ref.read(slProvider)<PlaylistRepository>(),
                );

                await deletePlaylist.call(
                  PlaylistId(widget.playlist.playlistId!),
                );

                ref.invalidate(libraryPlaylistsProvider);

                if (context.mounted) {
                  context.pop(); // Retourner à la bibliothèque
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.playlistDeletedSuccess)),
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

  void _openMedia(BuildContext context, ContentReference reference) {
    final media = MoviMedia(
      id: reference.id,
      title: reference.title.value,
      type: reference.type == ContentType.movie
          ? MoviMediaType.movie
          : MoviMediaType.series,
      poster: reference.poster,
    );

    if (reference.type == ContentType.movie) {
      context.push(AppRouteNames.movie, extra: media);
    } else {
      context.push(AppRouteNames.tv, extra: media);
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

  Widget _getPlaylistIcon() {
    switch (widget.playlist.type) {
      case LibraryPlaylistType.inProgress:
        return const Icon(
          Icons.play_circle_outline,
          color: Colors.white,
          size: 64,
        );
      case LibraryPlaylistType.favoriteMovies:
        return Image.asset(
          AppAssets.iconMovie,
          width: 64,
          height: 64,
          color: Colors.white,
        );
      case LibraryPlaylistType.favoriteSeries:
        return Image.asset(
          AppAssets.iconSerie,
          width: 64,
          height: 64,
          color: Colors.white,
        );
      case LibraryPlaylistType.watchHistory:
        return Image.asset(
          AppAssets.iconAvancer,
          width: 64,
          height: 64,
          color: Colors.white,
        );
      case LibraryPlaylistType.userPlaylist:
        return Image.asset(
          AppAssets.iconPlaylist,
          width: 64,
          height: 64,
          color: Colors.white,
        );
      case LibraryPlaylistType.actor:
        return MoviPlaceholderCard(
          type: PlaceholderType.person,
          width: 64,
          height: 64,
        );
    }
  }

  Future<Uri?> _getBackdropWithNullLanguage(ContentReference reference) async {
    try {
      final tmdbClient = sl<TmdbClient>();
      final images = sl<TmdbImageResolver>();

      final tmdbId = int.tryParse(reference.id);
      if (tmdbId == null) return null;

      final isMovie = reference.type == ContentType.movie;
      final jsonImages = await tmdbClient.getJson(
        isMovie ? 'movie/$tmdbId/images' : 'tv/$tmdbId/images',
        query: {'include_image_language': 'null'},
      );

      final backdrops = jsonImages['backdrops'] as List<dynamic>?;
      if (backdrops == null || backdrops.isEmpty) return null;

      // Sélectionner le backdrop avec iso_639_1 == null
      final noLangBackdrops = backdrops
          .whereType<Map<String, dynamic>>()
          .where((m) => m['iso_639_1'] == null)
          .toList();

      if (noLangBackdrops.isNotEmpty) {
        final backdropPath = noLangBackdrops.first['file_path']?.toString();
        if (backdropPath != null) {
          return images.backdrop(backdropPath, size: 'w780');
        }
      }

      // Fallback sur le premier backdrop disponible
      final firstBackdrop = backdrops.first as Map<String, dynamic>?;
      final backdropPath = firstBackdrop?['file_path']?.toString();
      if (backdropPath != null) {
        return images.backdrop(backdropPath, size: 'w780');
      }

      return null;
    } catch (_) {
      return null;
    }
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
            // En-tête avec bouton retour et menu (pour playlists utilisateur)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.pop(),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 35,
                          height: 35,
                          child: Image.asset(AppAssets.iconBack),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.actionBack,
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
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (widget.playlist.type == LibraryPlaylistType.userPlaylist)
                    IconButton(
                      icon: Image.asset(
                        AppAssets.iconMore,
                        width: 30,
                        height: 30,
                        color: Colors.white,
                      ),
                      onPressed: () => _showPlaylistMenu(context, ref),
                    ),
                ],
              ),
            ),
            // Hero section (350px)
            itemsAsync.when(
              loading: () => const SizedBox(height: 350),
              error: (_, __) => const SizedBox(height: 350),
              data: (items) {
                final itemCount = items.length;
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
                            colors: [accentColor, Color(0xFF0D2745)],
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
                      // Logo centré au milieu
                      Center(child: _getPlaylistIcon()),
                      // Titre à 50px du bottom
                      Positioned(
                        bottom: 58,
                        left: 0,
                        right: 0,
                        child: Text(
                          widget.playlist.title,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(
                                context,
                              ).textTheme.headlineSmall?.copyWith(
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
                      // Nombre d'éléments à 34px du bottom (16px sous le titre)
                      Positioned(
                        bottom: 24,
                        left: 0,
                        right: 0,
                          child: Text(
                            itemCount == 1
                                ? AppLocalizations.of(context)!.playlistItemCount(itemCount)
                                : AppLocalizations.of(context)!.playlistItemCountPlural(itemCount),
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
              },
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
                  final sortedItems = _sortItems(
                    items,
                    _sortType,
                    playlistItems: playlistItems,
                  );

                  return Column(
                    children: [
                      // Bouton primaire "Lire aléatoirement" (si non vide)
                      if (!isEmpty)
                        MoviPrimaryButton(
                          label: AppLocalizations.of(context)!.playlistPlayRandomly,
                          assetIcon: AppAssets.iconPlay,
                          onPressed: () => _playRandomly(context, sortedItems),
                        ),
                      // Pills "Ajouter" et "Trier" (si non vide ou playlist utilisateur)
                      if (!isEmpty ||
                          widget.playlist.type ==
                              LibraryPlaylistType.userPlaylist) ...[
                        if (!isEmpty) const SizedBox(height: 12),
                        Row(
                          children: [
                            // Pill "Ajouter" (uniquement pour playlists utilisateur)
                            if (widget.playlist.type ==
                                LibraryPlaylistType.userPlaylist)
                              GestureDetector(
                                onTap: () {
                                  if (widget.playlist.playlistId != null) {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                            0.9,
                                        child: AddMediaSearchModal(
                                          playlistId:
                                              widget.playlist.playlistId!,
                                        ),
                                      ),
                                    ).then((_) {
                                      // Rafraîchir la liste après ajout
                                      if (widget.playlist.playlistId != null) {
                                        ref.invalidate(
                                          playlistItemsProvider(
                                            widget.playlist.playlistId!,
                                          ),
                                        );
                                        ref.invalidate(
                                          playlistContentReferencesProvider(
                                            widget.playlist.playlistId!,
                                          ),
                                        );
                                      }
                                      ref.invalidate(libraryPlaylistsProvider);
                                    });
                                  }
                                },
                                child: MoviPill(
                                  AppLocalizations.of(context)!.playlistAddButton,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  trailingIcon: Image.asset(
                                    AppAssets.iconPlus,
                                    width: 16,
                                    height: 16,
                                  ),
                                ),
                              ),
                            // Pill "Trier" (si non vide)
                            if (!isEmpty) ...[
                              if (widget.playlist.type ==
                                  LibraryPlaylistType.userPlaylist)
                                const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _showSortMenu(context, ref),
                                child: MoviPill(
                                  AppLocalizations.of(context)!.playlistSortButton,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  trailingIcon: const Icon(
                                    Icons.arrow_drop_down,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            // Liste des médias
            Expanded(
              child: itemsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text(
                    'Erreur: $error',
                    style: const TextStyle(color: Colors.white),
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
                  final sortedItems = _sortItems(
                    items,
                    _sortType,
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
    return FutureBuilder<
      ({Duration? duration, int? seasonCount, Uri? backdrop})
    >(
      future:
          Future.wait([
            _getMediaInfo(ref, reference),
            _getBackdropWithNullLanguage(reference),
          ]).then(
            (results) => (
              duration: (results[0] as ({Duration? duration, int? seasonCount}))
                  .duration,
              seasonCount:
                  (results[0] as ({Duration? duration, int? seasonCount}))
                      .seasonCount,
              backdrop: results[1] as Uri?,
            ),
          ),
      builder: (context, snapshot) {
        final backdrop = snapshot.data?.backdrop;
        final duration = snapshot.data?.duration;
        final seasonCount = snapshot.data?.seasonCount;

        // Pour les playlists utilisateur, permettre la suppression
        final canDelete =
            widget.playlist.type == LibraryPlaylistType.userPlaylist &&
            playlistId != null &&
            playlistItem != null &&
            playlistItem.position != null;

        Widget content = GestureDetector(
          onTap: () => _openMedia(context, reference),
          onLongPress: canDelete
              ? () => _showDeleteItemDialog(
                  context,
                  ref,
                  reference,
                  playlistItem,
                  playlistId,
                )
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
                  child: backdrop != null
                      ? Image.network(
                          backdrop.toString(),
                          width: 180,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 180,
                            height: 100,
                            color: const Color(0xFF222222),
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.white54,
                              size: 32,
                            ),
                          ),
                        )
                      : Container(
                          width: 180,
                          height: 100,
                          color: const Color(0xFF222222),
                          child: const Icon(
                            Icons.movie,
                            color: Colors.white54,
                            size: 32,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                // Informations
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Titre
                      Text(
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
                            // Espace entre année et rating
                            if (reference.year != null &&
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

        // Envelopper dans Dismissible pour swipe vers la gauche (playlists utilisateur uniquement)
        if (canDelete) {
          return Dismissible(
            key: Key('${playlistId}_${reference.id}_${playlistItem.position}'),
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
              _removeItemFromPlaylist(context, ref, playlistItem, playlistId);
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
        content: Text(AppLocalizations.of(context)!.playlistRemoveItemConfirm(reference.title.value)),
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
      final removePlaylistItem = RemovePlaylistItem(
        ref.read(slProvider)<PlaylistRepository>(),
      );

      await removePlaylistItem.call(
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
            content: Text(AppLocalizations.of(context)!.playlistItemRemovedSuccess),
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
