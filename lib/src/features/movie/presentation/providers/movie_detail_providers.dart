import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/movie/domain/repositories/movie_repository.dart';
import 'package:movi/src/features/movie/data/repositories/movie_repository_impl.dart';
import 'package:movi/src/features/movie/data/datasources/movie_local_data_source.dart';
import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
import 'package:movi/src/features/movie/presentation/models/movie_detail_view_model.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/features/movie/domain/usecases/filter_recommendations_by_iptv.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/features/saga/domain/repositories/saga_repository.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/core/models/models.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/features/movie/domain/usecases/build_movie_video_source.dart';
import 'package:movi/src/features/movie/domain/usecases/get_movie_availability_on_iptv.dart';
import 'package:movi/src/features/movie/domain/usecases/mark_movie_as_seen.dart';
import 'package:movi/src/features/movie/domain/usecases/mark_movie_as_unseen.dart';
import 'package:movi/src/features/movie/domain/usecases/add_movie_to_playlist.dart';
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';

/// Provider pour MovieRepository avec userId actuel
final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return MovieRepositoryImpl(
    ref.watch(tmdbMovieRemoteDataSourceProvider),
    ref.watch(tmdbImageResolverProvider),
    ref.watch(watchlistLocalRepositoryProvider),
    ref.watch(movieLocalDataSourceProvider),
    ref.watch(continueWatchingLocalRepositoryProvider),
    ref.watch(appStateControllerProvider),
    userId: userId,
  );
});

/// Provider pour vérifier si un film est dans les favoris
final movieIsFavoriteProvider = FutureProvider.family<bool, String>((
  ref,
  movieId,
) async {
  final repo = ref.watch(movieRepositoryProvider);
  return await repo.isInWatchlist(MovieId(movieId));
});

/// Notifier pour basculer le statut favori d'un film
class MovieToggleFavoriteNotifier extends Notifier<void> {
  @override
  void build() {
    // État initial vide, la méthode toggle() fait le travail
  }

  Future<void> toggle(String movieId) async {
    final repo = ref.read(movieRepositoryProvider);
    final isFavorite = await ref.read(movieIsFavoriteProvider(movieId).future);
    await repo.setWatchlist(MovieId(movieId), saved: !isFavorite);
    ref.invalidate(movieIsFavoriteProvider(movieId));
    // Invalider les playlists de la bibliothèque pour mettre à jour les favoris
    ref.invalidate(libraryPlaylistsProvider);
  }
}

/// Provider pour basculer le statut favori d'un film
final movieToggleFavoriteProvider =
    NotifierProvider<MovieToggleFavoriteNotifier, void>(
      MovieToggleFavoriteNotifier.new,
    );

/// Providers pour les nouveaux use cases
final buildMovieVideoSourceUseCaseProvider = Provider<BuildMovieVideoSource>(
  (ref) => ref.watch(slProvider)<BuildMovieVideoSource>(),
);

final getMovieAvailabilityOnIptvUseCaseProvider =
    Provider<GetMovieAvailabilityOnIptv>(
      (ref) => ref.watch(slProvider)<GetMovieAvailabilityOnIptv>(),
    );

final markMovieAsSeenUseCaseProvider = Provider<MarkMovieAsSeen>(
  (ref) => ref.watch(slProvider)<MarkMovieAsSeen>(),
);

final markMovieAsUnseenUseCaseProvider = Provider<MarkMovieAsUnseen>(
  (ref) => ref.watch(slProvider)<MarkMovieAsUnseen>(),
);

final addMovieToPlaylistUseCaseProvider = Provider<AddMovieToPlaylist>(
  (ref) => ref.watch(slProvider)<AddMovieToPlaylist>(),
);

final movieDetailControllerProvider =
    FutureProvider.family<MovieDetailViewModel, String>((ref, movieId) async {
      final lang = ref.watch(currentLanguageCodeProvider);
      final locator = ref.watch(slProvider);
      final logger = locator<AppLogger>();
      final repo = ref.watch(movieRepositoryProvider);
      final id = MovieId(movieId);
      final t0 = DateTime.now();
      final detail = await repo.getMovie(id);
      final t1 = DateTime.now();
      final people = await repo.getCredits(id);
      final t2 = DateTime.now();
      final reco = await repo.getRecommendations(id);
      final t3 = DateTime.now();
      final filterReco = locator<FilterRecommendationsByIptvAvailability>();
      final filtered = await filterReco(reco);
      logger.debug(
        'movie_detail fetch id=$movieId lang=$lang durations: detail=${t1.difference(t0).inMilliseconds}ms, credits=${t2.difference(t1).inMilliseconds}ms, reco=${t3.difference(t2).inMilliseconds}ms',
        category: 'movie_detail',
      );
      return MovieDetailViewModel.fromDomain(
        detail: detail,
        credits: people,
        recommendations: filtered,
        language: lang,
      );
    });

/// Disponibilité du film sur IPTV
final movieAvailabilityProvider = FutureProvider.family<bool, String>((
  ref,
  id,
) async {
  final usecase = ref.watch(getMovieAvailabilityOnIptvUseCaseProvider);
  return await usecase(id);
});

/// Entrée d'historique brute pour un film
final movieHistoryProvider =
    FutureProvider.family<PlaybackHistoryEntry?, String>((ref, id) async {
      try {
        final historyRepo = ref.watch(slProvider)<PlaybackHistoryRepository>();
        return await historyRepo.getEntry(id, ContentType.movie);
      } catch (_) {
        return null;
      }
    });

/// Statut vu/non vu basé sur l'historique
final movieSeenProvider = FutureProvider.family<bool, String>((ref, id) async {
  try {
    final entry = await ref.read(movieHistoryProvider(id).future);
    if (entry == null ||
        entry.duration == null ||
        entry.duration!.inSeconds <= 0) {
      return false;
    }
    final progress =
        (entry.lastPosition?.inSeconds ?? 0) / entry.duration!.inSeconds;
    return progress >= 0.9;
  } catch (_) {
    return false;
  }
});

/// Construction de la VideoSource du film
final buildMovieVideoSourceProvider =
    FutureProvider.family<
      VideoSource?,
      ({String movieId, String title, Uri? poster})
    >((ref, args) async {
      final usecase = ref.watch(buildMovieVideoSourceUseCaseProvider);
      return await usecase(
        movieId: args.movieId,
        title: args.title,
        poster: args.poster,
      );
    });

/// Provider pour vérifier si une saga est dans les favoris
/// Utilise l'ID de la saga comme clé pour partager l'état entre tous les films de la saga
final sagaIsFavoriteProvider = FutureProvider.family<bool, String>((
  ref,
  sagaId,
) async {
  final watchlist = ref.watch(slProvider)<WatchlistLocalRepository>();
  final userId = ref.read(currentUserIdProvider);
  return await watchlist.exists(sagaId, ContentType.saga, userId: userId);
});

/// Notifier pour basculer le statut favori d'une saga
class SagaToggleFavoriteNotifier extends Notifier<void> {
  @override
  void build() {
    // État initial vide, la méthode toggle() fait le travail
  }

  Future<void> toggle(String sagaId, SagaSummary sagaLink) async {
    final watchlist = ref.read(slProvider)<WatchlistLocalRepository>();
    final userId = ref.read(currentUserIdProvider);
    final isFavorite = await ref.read(sagaIsFavoriteProvider(sagaId).future);

    if (isFavorite) {
      await watchlist.remove(sagaId, ContentType.saga, userId: userId);
    } else {
      await watchlist.upsert(
        WatchlistEntry(
          contentId: sagaId,
          type: ContentType.saga,
          title: sagaLink.title.value,
          poster: sagaLink.cover,
          addedAt: DateTime.now(),
          userId: userId,
        ),
      );
    }

    ref.invalidate(sagaIsFavoriteProvider(sagaId));
    // Invalider les playlists de la bibliothèque pour mettre à jour les favoris
    ref.invalidate(libraryPlaylistsProvider);
  }
}

/// Provider pour basculer le statut favori d'une saga
final sagaToggleFavoriteProvider =
    NotifierProvider<SagaToggleFavoriteNotifier, void>(
      SagaToggleFavoriteNotifier.new,
    );

/// Provider pour charger les films d'une saga
final sagaMoviesProvider = FutureProvider.family<List<MoviMedia>, SagaSummary?>(
  (ref, sagaLink) async {
    if (sagaLink == null) {
      return const [];
    }

    try {
      final sagaRepo = ref.watch(slProvider)<SagaRepository>();
      final saga = await sagaRepo.getSaga(sagaLink.id);

      // Convertir les SagaEntry en MoviMedia et trier par timelineYear
      final movies = saga.timeline
          .where((entry) => entry.reference.type == ContentType.movie)
          .map((entry) {
            final ref = entry.reference;
            return MoviMedia(
              id: ref.id,
              title: ref.title.display,
              poster: ref.poster,
              year: entry.timelineYear,
              type: MoviMediaType.movie,
            );
          })
          .toList();

      // Trier par année de sortie (timelineYear)
      movies.sort((a, b) {
        final yearA = a.year ?? 0;
        final yearB = b.year ?? 0;
        return yearA.compareTo(yearB);
      });

      return movies;
    } catch (e) {
      // En cas d'erreur, retourner une liste vide
      return const [];
    }
  },
);

/// Providers DI pour les dépendances Movie
final tmdbMovieRemoteDataSourceProvider = Provider<TmdbMovieRemoteDataSource>((
  ref,
) {
  return ref.watch(slProvider)<TmdbMovieRemoteDataSource>();
});

final movieLocalDataSourceProvider = Provider<MovieLocalDataSource>((ref) {
  return ref.watch(slProvider)<MovieLocalDataSource>();
});

final watchlistLocalRepositoryProvider = Provider<WatchlistLocalRepository>((
  ref,
) {
  return ref.watch(slProvider)<WatchlistLocalRepository>();
});

final continueWatchingLocalRepositoryProvider =
    Provider<ContinueWatchingLocalRepository>((ref) {
      return ref.watch(slProvider)<ContinueWatchingLocalRepository>();
    });

final tmdbImageResolverProvider = Provider<TmdbImageResolver>((ref) {
  return ref.watch(slProvider)<TmdbImageResolver>();
});
