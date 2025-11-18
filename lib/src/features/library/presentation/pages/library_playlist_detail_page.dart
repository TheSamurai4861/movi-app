import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/core/utils/utils.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/models/models.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/features/library/presentation/widgets/library_playlist_card.dart';
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

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes}m';
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
                          'Retour',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                ],
              ),
            ),
            // Icône et titre centrés
            FutureBuilder<List<ContentReference>>(
              future: itemsFuture,
              builder: (context, snapshot) {
                final itemCount = snapshot.data?.length ?? 0;
                return Column(
                  children: [
                    const Icon(
                      Icons.movie,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      playlist.title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ) ??
                          const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$itemCount éléments',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white70,
                          ) ??
                          const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            // Bouton "Lire aléatoirement"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FutureBuilder<List<ContentReference>>(
                future: itemsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return MoviPrimaryButton(
                    label: 'Lire aléatoirement',
                    assetIcon: AppAssets.iconPlay,
                    onPressed: () => _playRandomly(context, snapshot.data!),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
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

  Widget _buildMediaItem(BuildContext context, WidgetRef ref, ContentReference reference) {
    return FutureBuilder<({Duration? duration, int? seasonCount})>(
      future: _getMediaInfo(ref, reference),
      builder: (context, snapshot) {
        final pills = <Widget>[];
        
        // Année
        if (reference.year != null) {
          pills.add(
            MoviPill(
              reference.year.toString(),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          );
        }
        
        // Durée pour les films ou nombre de saisons pour les séries
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          final data = snapshot.data!;
          if (reference.type == ContentType.movie && data.duration != null) {
            pills.add(
              MoviPill(
                _formatDuration(data.duration!),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            );
          } else if (reference.type == ContentType.series && data.seasonCount != null) {
            pills.add(
              MoviPill(
                '${data.seasonCount} ${data.seasonCount == 1 ? 'saison' : 'saisons'}',
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            );
          }
        }
        
        return GestureDetector(
          onTap: () => _openMedia(context, reference),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Poster arrondi
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: reference.poster != null
                      ? Image.network(
                          reference.poster!.toString(),
                          width: 100,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 100,
                            height: 150,
                            color: const Color(0xFF222222),
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.white54,
                              size: 32,
                            ),
                          ),
                        )
                      : Container(
                          width: 100,
                          height: 150,
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
                      if (pills.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: pills,
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

  Future<({Duration? duration, int? seasonCount})> _getMediaInfo(
    WidgetRef ref,
    ContentReference reference,
  ) async {
    if (reference.type == ContentType.movie) {
      // MovieSummary n'a pas de durée, on retourne null pour l'instant
      // TODO: Charger les détails complets du film si nécessaire
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

