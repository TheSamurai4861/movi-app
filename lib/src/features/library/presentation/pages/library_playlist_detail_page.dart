import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/core/utils/utils.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/widgets/movi_media_card.dart';
import 'package:movi/src/core/models/models.dart';
import 'package:movi/src/features/library/presentation/widgets/library_playlist_card.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/features/library/domain/repositories/library_repository.dart';
import 'package:movi/src/features/playlist/playlist.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

class LibraryPlaylistDetailPage extends ConsumerWidget {
  const LibraryPlaylistDetailPage({super.key, required this.playlist});

  final LibraryPlaylistItem playlist;

  Future<List<ContentReference>> _loadPlaylistItems(
    LibraryRepository repository,
    PlaylistRepository playlistRepository,
  ) async {
    switch (playlist.type) {
      case LibraryPlaylistType.favoriteMovies:
        final movies = await repository.getLikedMovies();
        return movies
            .map(
              (m) => ContentReference(
                id: m.id.value,
                title: m.title,
                type: ContentType.movie,
                poster: m.poster,
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
        if (playlist.playlistId == null) return [];
        try {
          final playlistDetail = await playlistRepository.getPlaylist(
            PlaylistId(playlist.playlistId!),
          );
          return playlistDetail.items
              .map((item) => item.reference)
              .toList();
        } catch (e) {
          return [];
        }
      case LibraryPlaylistType.actor:
        return [];
    }
  }

  void _playRandomly(BuildContext context, List<ContentReference> items) {
    if (items.isEmpty) return;
    items.shuffle();
    final firstItem = items.first;
    // TODO: Implémenter la lecture aléatoire
    // Pour l'instant, ouvrir le premier élément
    _openMedia(context, firstItem);
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(libraryRepositoryProvider);
    final playlistRepository = ref.watch(playlistRepositoryProvider);
    final itemsFuture = Future.microtask(() => _loadPlaylistItems(repository, playlistRepository));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // En-tête avec bouton retour
            Padding(
              padding: AppSpacing.page,
              child: Row(
                children: [
                  IconButton(
                    icon: Image.asset(
                      AppAssets.iconBack,
                      width: 24,
                      height: 24,
                      color: Colors.white,
                    ),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      playlist.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ) ??
                          const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            // Bouton "Lire aléatoirement"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FutureBuilder<List<ContentReference>>(
                future: itemsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _playRandomly(context, snapshot.data!),
                      icon: Image.asset(
                        AppAssets.iconPlay,
                        width: 20,
                        height: 20,
                        color: Colors.white,
                      ),
                      label: const Text('Lire aléatoirement'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2160AB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Liste des médias
            Expanded(
              child: FutureBuilder<List<ContentReference>>(
                future: itemsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Erreur: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'Aucun élément dans cette playlist',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white70,
                            ) ??
                            const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildMediaItem(context, item);
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

  Widget _buildMediaItem(BuildContext context, ContentReference reference) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _openMedia(context, reference),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: reference.poster != null
                ? Image.network(
                    reference.poster!.toString(),
                    width: 120,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 120,
                      height: 180,
                      color: cs.surfaceContainerHighest,
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                      ),
                    ),
                  )
                : Container(
                    width: 120,
                    height: 180,
                    color: cs.surfaceContainerHighest,
                    child: const Icon(
                      Icons.movie,
                      color: Colors.white54,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          // Informations
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reference.title.value,
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
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2160AB).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reference.type == ContentType.movie ? 'Film' : 'Série',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

