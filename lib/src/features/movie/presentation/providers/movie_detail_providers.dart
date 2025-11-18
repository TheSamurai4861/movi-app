import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
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
import 'package:movi/src/core/storage/repositories/watchlist_local_repository.dart';

/// Provider pour MovieRepository avec userId actuel
final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return MovieRepositoryImpl(
    ref.watch(slProvider)<TmdbMovieRemoteDataSource>(),
    ref.watch(slProvider)<TmdbImageResolver>(),
    ref.watch(slProvider)<WatchlistLocalRepository>(),
    ref.watch(slProvider)<MovieLocalDataSource>(),
    ref.watch(slProvider)<ContinueWatchingLocalRepository>(),
    ref.watch(slProvider)<AppStateController>(),
    userId: userId,
  );
});

/// Provider pour vérifier si un film est dans les favoris
final movieIsFavoriteProvider =
    FutureProvider.family<bool, String>((ref, movieId) async {
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

/// Provider pour vérifier si une saga est dans les favoris
/// Utilise l'ID de la saga comme clé pour partager l'état entre tous les films de la saga
final sagaIsFavoriteProvider =
    FutureProvider.family<bool, String>((ref, sagaId) async {
  final watchlist = ref.watch(slProvider)<WatchlistLocalRepository>();
  final userId = ref.read(currentUserIdProvider);
  return await watchlist.exists(
    sagaId,
    ContentType.saga,
    userId: userId,
  );
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
      await watchlist.remove(
        sagaId,
        ContentType.saga,
        userId: userId,
      );
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
final sagaMoviesProvider = FutureProvider.family<List<MoviMedia>, SagaSummary?>((ref, sagaLink) async {
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
});
