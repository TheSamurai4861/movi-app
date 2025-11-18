import 'package:movi/src/features/movie/domain/entities/movie.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/movie/domain/repositories/movie_repository.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/value_objects/synopsis.dart';
import 'package:movi/src/shared/domain/value_objects/content_rating.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
import 'package:movi/src/features/movie/data/datasources/movie_local_data_source.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart';

class MovieRepositoryImpl implements MovieRepository {
  MovieRepositoryImpl(
    this._remote,
    this._images,
    this._watchlist,
    this._local,
    this._continueWatching,
    this._appState, {
    String? userId,
  }) : _userId = userId ?? 'default';

  final TmdbMovieRemoteDataSource _remote;
  final TmdbImageResolver _images;
  final WatchlistLocalRepository _watchlist;
  final MovieLocalDataSource _local;
  final ContinueWatchingLocalRepository _continueWatching;
  final AppStateController _appState;
  final String _userId;

  @override
  Future<Movie> getMovie(MovieId id) async {
    final movieId = int.parse(id.value);
    final cached = await _local.getMovieDetail(movieId);
    if (cached != null) {
      return _mapDetail(cached);
    }
    final remote = await _remote.fetchMovieFull(
      movieId,
      language: _appState.preferredLocale,
    );
    await _local.saveMovieDetail(dto: remote);
    return _mapDetail(remote);
  }

  @override
  Future<List<PersonSummary>> getCredits(MovieId id) async {
    final detail = await getMovie(id);
    final combined = <PersonSummary>[...detail.directors, ...detail.cast];
    return combined.take(10).toList(growable: false);
  }

  @override
  Future<List<MovieSummary>> getRecommendations(MovieId id) async {
    final movieId = int.parse(id.value);
    final cached = await _local.getRecommendations(movieId);
    if (cached != null && cached.isNotEmpty) {
      return cached.map(_mapSummary).whereType<MovieSummary>().toList();
    }
    // Si le cache est vide ou n'existe pas, récupérer depuis le réseau
    // Utiliser fetchMovieFull qui inclut les recommandations via append_to_response
    final dto = await _remote.fetchMovieFull(
      movieId,
      language: _appState.preferredLocale,
    );
    final recommendations = dto.recommendations;
    // Sauvegarder les recommandations dans le cache même si la liste est vide
    // pour éviter les appels répétés pour les films sans recommandations
    if (recommendations.isNotEmpty) {
      await _local.saveRecommendations(
        movieId: movieId,
        summaries: recommendations,
      );
    }
    return recommendations.map(_mapSummary).whereType<MovieSummary>().toList();
  }

  @override
  Future<List<MovieSummary>> getContinueWatching() async {
    final entries = await _continueWatching.readAll(ContentType.movie);
    return entries
        .where((e) => e.poster != null)
        .map(
          (e) => MovieSummary(
            id: MovieId(e.contentId),
            title: MediaTitle(e.title),
            poster: e.poster!,
          ),
        )
        .toList();
  }

  @override
  Future<List<MovieSummary>> searchMovies(String query) async {
    final results = await _remote.searchMovies(
      query,
      language: _appState.preferredLocale,
    );
    return results.map(_mapSummary).whereType<MovieSummary>().toList();
  }

  @override
  Future<bool> isInWatchlist(MovieId id) async =>
      _watchlist.exists(id.value, ContentType.movie, userId: _userId);

  @override
  Future<void> setWatchlist(MovieId id, {required bool saved}) async {
    if (saved) {
      final summary = await getMovie(id);
      await _watchlist.upsert(
        WatchlistEntry(
          contentId: id.value,
          type: ContentType.movie,
          title: summary.title.value,
          poster: summary.poster,
          addedAt: DateTime.now(),
          userId: _userId,
        ),
      );
    } else {
      await _watchlist.remove(id.value, ContentType.movie, userId: _userId);
    }
  }

  @override
  Future<void> refreshMetadata(MovieId id) async {
    final movieId = int.parse(id.value);
    await _local.clearMovieDetail(movieId);
    await _local.clearRecommendations(movieId);
  }

  Movie _mapDetail(TmdbMovieDetailDto dto) {
    final posterCandidate = dto.posterBackground ?? dto.posterPath;
    final poster = _images.poster(posterCandidate, size: 'w780');
    final backdrop = _images.backdrop(dto.backdropPath, size: 'w1280');
    if (poster == null) {
      throw StateError('Movie ${dto.id} missing poster');
    }
    return Movie(
      id: MovieId(dto.id.toString()),
      tmdbId: dto.id,
      title: MediaTitle(dto.title),
      synopsis: Synopsis(dto.overview),
      duration: Duration(minutes: dto.runtime ?? 0),
      poster: poster,
      backdrop: backdrop,
      releaseDate:
          _parseDate(dto.releaseDate) ?? DateTime.fromMillisecondsSinceEpoch(0),
      rating: _mapRating(dto.voteAverage),
      voteAverage: dto.voteAverage,
      genres: dto.genres,
      cast: dto.cast.take(10).map(_mapCast).toList(),
      directors: dto.directors
          .map(
            (crew) => PersonSummary(
              id: PersonId(crew.id.toString()),
              tmdbId: crew.id,
              name: crew.name,
              role: 'Director',
              photo: _images.poster(crew.profilePath),
            ),
          )
          .toList(),
      tags: dto.genres,
      sagaLink: _mapSagaLink(dto),
    );
  }

  SagaSummary? _mapSagaLink(TmdbMovieDetailDto dto) {
    final col = dto.belongsToCollection;
    if (col == null) return null;
    final cover = _images.poster(col.posterPath);
    return SagaSummary(
      id: SagaId(col.id.toString()),
      tmdbId: col.id,
      title: MediaTitle(col.name),
      cover: cover,
      itemCount: null,
    );
  }

  PersonSummary _mapCast(TmdbMovieCastDto cast) {
    return PersonSummary(
      id: PersonId(cast.id.toString()),
      tmdbId: cast.id,
      name: cast.name,
      role: cast.character,
      photo: _images.poster(cast.profilePath),
    );
  }

  MovieSummary? _mapSummary(TmdbMovieSummaryDto summary) {
    final poster = _images.poster(summary.posterPath, size: 'w342');
    if (poster == null) return null;
    return MovieSummary(
      id: MovieId(summary.id.toString()),
      tmdbId: summary.id,
      title: MediaTitle(summary.title),
      poster: poster,
      backdrop: _images.backdrop(summary.backdropPath),
      releaseYear: _parseDate(summary.releaseDate)?.year,
      tags: const [],
    );
  }

  DateTime? _parseDate(String? date) {
    if (date == null || date.isEmpty) {
      return null;
    }
    return DateTime.tryParse(date);
  }

  ContentRating? _mapRating(double? voteAverage) {
    if (voteAverage == null) return null;
    if (voteAverage >= 8.0) return ContentRating.pg13;
    if (voteAverage >= 5.0) return ContentRating.pg;
    return ContentRating.unrated;
  }
}
