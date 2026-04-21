import 'package:flutter/foundation.dart';
import 'package:movi/src/core/shared/failure.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/features/movie/data/datasources/movie_local_data_source.dart';
import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
import 'package:movi/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart';
import 'package:movi/src/features/movie/domain/entities/movie.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/movie/domain/repositories/movie_repository.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/shared/data/services/tmdb_detail_cache_data_source.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/shared/domain/value_objects/content_rating.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/value_objects/synopsis.dart';

class MovieRepositoryImpl implements MovieRepository {
  MovieRepositoryImpl(
    this._remote,
    this._images,
    this._watchlist,
    this._local,
    this._continueWatching,
    this._appState,
    this._detailCache, {
    String? userId,
  }) : _userId = userId ?? 'default';

  final TmdbMovieRemoteDataSource _remote;
  final TmdbImageResolver _images;
  final WatchlistLocalRepository _watchlist;
  final MovieLocalDataSource _local;
  final ContinueWatchingLocalRepository _continueWatching;
  final AppStateController _appState;
  final TmdbDetailCacheDataSource _detailCache;
  final String _userId;
  final Map<String, Future<void>> _backgroundRefreshes =
      <String, Future<void>>{};

  String get _languageCode {
    final locale = _appState.preferredLocale;
    final country = locale.countryCode;
    if (country == null || country.isEmpty) {
      return locale.languageCode;
    }
    return '${locale.languageCode}-$country';
  }

  @override
  Future<Movie> getMovie(MovieId id) async {
    final dto = await _loadMovieDetailFullDto(int.parse(id.value));
    return _mapDetail(dto);
  }

  @override
  Future<List<PersonSummary>> getCredits(MovieId id) async {
    final dto = await _loadMovieDetailFullDto(int.parse(id.value));
    return _buildCredits(_mapDetail(dto));
  }

  @override
  Future<List<MovieSummary>> getRecommendations(MovieId id) async {
    return _loadRecommendations(int.parse(id.value));
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
    final results = await _remote.searchMovies(query, language: _languageCode);
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
    await _local.clearMovieDetailLang(movieId, _languageCode);
    await _local.clearRecommendationsLang(movieId, _languageCode);
    await _detailCache.clearMovie(movieId, language: _languageCode);
  }

  Future<MovieDetailBundle> loadMovieDetailBundle(MovieId id) async {
    final movieId = int.parse(id.value);
    final dto = await _loadMovieDetailFullDto(movieId);
    final detail = _mapDetail(dto);
    final recommendations = await _loadRecommendations(
      movieId,
      fallback: dto.recommendations,
    );
    return MovieDetailBundle(
      detail: detail,
      credits: _buildCredits(detail),
      recommendations: recommendations,
    );
  }

  Future<TmdbMovieDetailDto> _loadMovieDetailFullDto(int movieId) async {
    final cached = await _detailCache.getCachedMovieDetailFull(
      movieId: movieId,
      language: _languageCode,
    );
    if (cached.isFresh) {
      _logCache('movie_detail_full', 'cache_hit_fresh', movieId);
      return cached.value!;
    }
    if (cached.isStale) {
      _logCache('movie_detail_full', 'cache_hit_stale', movieId);
      _scheduleBackgroundRefresh(movieId);
      return cached.value!;
    }

    final migrated = await _local.getMovieDetailLang(
      movieId,
      lang: _languageCode,
    );
    if (migrated != null) {
      _logCache(
        'movie_detail_full',
        'cache_hit_fresh',
        movieId,
        source: 'legacy',
      );
      await _persistMoviePayload(movieId, migrated);
      return migrated;
    }

    _logCache('movie_detail_full', 'cache_miss', movieId);
    return _fetchAndPersistMovieFull(movieId);
  }

  Future<List<MovieSummary>> _loadRecommendations(
    int movieId, {
    List<TmdbMovieSummaryDto>? fallback,
  }) async {
    final cached = await _detailCache.getCachedMovieRecommendations(
      movieId: movieId,
      language: _languageCode,
    );
    if (cached.isFresh) {
      _logCache('movie_recommendations', 'cache_hit_fresh', movieId);
      return cached.value!.map(_mapSummary).whereType<MovieSummary>().toList();
    }
    if (cached.isStale) {
      _logCache('movie_recommendations', 'cache_hit_stale', movieId);
      _scheduleBackgroundRefresh(movieId);
      return cached.value!.map(_mapSummary).whereType<MovieSummary>().toList();
    }

    final migrated = await _local.getRecommendationsLang(
      movieId,
      lang: _languageCode,
    );
    if (migrated != null && migrated.isNotEmpty) {
      _logCache(
        'movie_recommendations',
        'cache_hit_fresh',
        movieId,
        source: 'legacy',
      );
      await _persistRecommendations(movieId, migrated);
      return migrated.map(_mapSummary).whereType<MovieSummary>().toList();
    }

    final source =
        fallback ?? (await _loadMovieDetailFullDto(movieId)).recommendations;
    if (source.isEmpty) {
      return const <MovieSummary>[];
    }
    _logCache('movie_recommendations', 'cache_miss', movieId);
    await _persistRecommendations(movieId, source);
    return source.map(_mapSummary).whereType<MovieSummary>().toList();
  }

  Future<TmdbMovieDetailDto> _fetchAndPersistMovieFull(int movieId) async {
    final locale = _appState.preferredLocale;
    try {
      final dto = await _remote.fetchMovieFull(
        movieId,
        language: _languageCode,
      );
      await _persistMoviePayload(movieId, dto);
      _debugLog('movie_detail_saved');
      return dto;
    } catch (e, st) {
      _debugLog('getMovie_failed error=$e\n$st');
      throw Failure.fromException(
        e,
        stackTrace: st,
        code: 'movie_detail_fetch_failed',
        context: <String, Object?>{
          'operation': 'getMovie',
          'movieId': movieId,
          'lang': locale,
        },
      );
    }
  }

  Future<void> _persistMoviePayload(int movieId, TmdbMovieDetailDto dto) async {
    await _detailCache.putMovieDetailLite(dto, language: _languageCode);
    await _detailCache.putMovieDetailFull(dto, language: _languageCode);
    await _local.saveMovieDetailLang(dto: dto, lang: _languageCode);
    await _persistRecommendations(movieId, dto.recommendations);
  }

  Future<void> _persistRecommendations(
    int movieId,
    List<TmdbMovieSummaryDto> recommendations,
  ) async {
    await _detailCache.putMovieRecommendations(
      recommendations,
      movieId: movieId,
      language: _languageCode,
    );
    if (recommendations.isNotEmpty) {
      await _local.saveRecommendationsLang(
        movieId: movieId,
        lang: _languageCode,
        summaries: recommendations,
      );
    }
  }

  void _scheduleBackgroundRefresh(int movieId) {
    final key = 'movie:$movieId:$_languageCode';
    if (_backgroundRefreshes.containsKey(key)) return;

    _logCache('movie_detail_full', 'background_refresh_started', movieId);
    final refresh = _fetchAndPersistMovieFull(movieId)
        .then((_) {
          _logCache(
            'movie_detail_full',
            'background_refresh_completed',
            movieId,
          );
        })
        .catchError((Object error, StackTrace stackTrace) {
          _debugLog(
            'background_refresh_failed resource=movie_detail_full movieId=$movieId lang=$_languageCode',
            error: error,
            stackTrace: stackTrace,
          );
        })
        .whenComplete(() {
          _backgroundRefreshes.remove(key);
        });
    _backgroundRefreshes[key] = refresh;
    unawaited(refresh);
  }

  List<PersonSummary> _buildCredits(Movie detail) {
    final combined = <PersonSummary>[...detail.directors, ...detail.cast];
    return combined.take(10).toList(growable: false);
  }

  void _logCache(String resource, String event, int movieId, {String? source}) {
    _debugLog(
      '$event resource=$resource movieId=$movieId lang=$_languageCode'
      '${source == null ? '' : ' source=$source'}',
    );
  }

  void _debugLog(String message, {Object? error, StackTrace? stackTrace}) {
    assert(() {
      final suffix = error == null ? '' : ' error=$error';
      final stack = stackTrace == null ? '' : '\n$stackTrace';
      debugPrint('[MovieRepositoryImpl] $message$suffix$stack');
      return true;
    }());
  }

  Movie _mapDetail(TmdbMovieDetailDto dto) {
    final poster = _images.poster(
      dto.posterPath ?? dto.posterBackground,
      size: 'w780',
    );

    if (poster == null) {
      throw StateError('Movie ${dto.id} missing poster');
    }

    final posterBackground =
        _images.poster(dto.posterBackground, size: 'w780') ?? poster;

    final backdrop = _images.backdrop(dto.backdropPath, size: 'w1280');
    final logo = _images.logo(dto.logoPath, size: 'w500');

    return Movie(
      id: MovieId(dto.id.toString()),
      tmdbId: dto.id,
      title: MediaTitle(dto.title),
      synopsis: Synopsis(dto.overview),
      duration: Duration(minutes: dto.runtime ?? 0),
      poster: poster,
      logo: logo,
      posterBackground: posterBackground,
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

class MovieDetailBundle {
  const MovieDetailBundle({
    required this.detail,
    required this.credits,
    required this.recommendations,
  });

  final Movie detail;
  final List<PersonSummary> credits;
  final List<MovieSummary> recommendations;
}
