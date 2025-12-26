/* lib/src/features/home/data/repositories/home_feed_repository_impl.dart */
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:movi/src/features/iptv/application/iptv_catalog_reader.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/features/iptv/iptv.dart';

import 'package:movi/src/shared/data/services/tmdb_cache_data_source.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/core/storage/services/cache_policy.dart';
import 'package:movi/src/shared/domain/services/tmdb_image_selector_service.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/core/shared/failure.dart';
import 'package:movi/src/core/utils/result.dart';

import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
import 'package:movi/src/features/movie/movie.dart';

import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';
import 'package:movi/src/features/tv/tv.dart';

import 'package:movi/src/features/home/domain/repositories/home_feed_repository.dart';
import 'package:movi/src/features/home/domain/usecases/load_continue_watching_media.dart';
import 'package:movi/src/features/home/domain/home_constants.dart';

class HomeFeedRepositoryImpl implements HomeFeedRepository {
  HomeFeedRepositoryImpl(
    this._moviesRemote,
    this._tvRemote,
    this._catalogReader,
    this._images,
    this._appState,
    this._tmdbCache,
    this._continueWatching,
  );

  final TmdbMovieRemoteDataSource _moviesRemote;
  final TmdbTvRemoteDataSource _tvRemote;
  final IptvCatalogReader _catalogReader;
  final TmdbImageResolver _images;
  final AppStateController _appState;
  final TmdbCacheDataSource _tmdbCache;
  final LoadContinueWatchingMedia _continueWatching;

  final Set<String> _enrichedKeys = <String>{};

  static const String _trendingWindow = 'week';
  static const int _maxTrendingPages = 1;
  static const int _heroLimit = 20;

  /// Code de langue à partir de la locale courante dans [AppState].
  ///
  /// Exemple : `fr-FR`, `en-US`, ou `en` si aucun pays n'est défini.
  String get _languageCode {
    final locale = _appState.preferredLocale;
    final country = locale.countryCode;
    if (country == null || country.isEmpty) {
      return locale.languageCode;
    }
    return '${locale.languageCode}-$country';
  }

  @override
  Future<Result<List<ContentReference>, Failure>> getHeroItems() async {
    try {
      final Set<int> availableMovies = await _collectAvailableMovieTmdbIds();
      final Set<int> availableSeries = await _collectAvailableSeriesTmdbIds();
      if (availableMovies.isEmpty && availableSeries.isEmpty) {
        // On ne montre pas de Trending "global" si l’utilisateur n’a aucun contenu
        // identifié (tmdb_id) dans ses playlists IPTV.
        return const Ok<List<ContentReference>, Failure>(<ContentReference>[]);
      }

      final movies = <ContentReference>[];
      final series = <ContentReference>[];

      // 1) Trending movies (intersect IPTV)
      if (availableMovies.isNotEmpty) {
        for (var page = 1; page <= _maxTrendingPages; page++) {
          final pageDtos = await _fetchTrendingMoviesPage(page);
          if (pageDtos.isEmpty) break;
          final matched = pageDtos
              .where((d) => availableMovies.contains(d.id))
              .toList(growable: false);
          movies.addAll(_mapMovieDtosToHeroCandidates(matched));
          if (movies.isNotEmpty) break;
        }
      }

      // 2) Trending series (intersect IPTV)
      if (availableSeries.isNotEmpty) {
        for (var page = 1; page <= _maxTrendingPages; page++) {
          final pageDtos = await _fetchTrendingShowsPage(page);
          if (pageDtos.isEmpty) break;
          final matched = pageDtos
              .where((d) => availableSeries.contains(d.id))
              .toList(growable: false);
          series.addAll(_mapTvDtosToHeroCandidates(matched));
          if (series.isNotEmpty) break;
        }
      }

      final ordered = _interleaveMoviesAndSeries(movies, series);
      return Ok<List<ContentReference>, Failure>(_takeFirst(ordered, _heroLimit));
    } catch (e, st) {
      debugPrint('[HomeFeedRepositoryImpl] getHeroItems error: $e\n$st');
      return Err<List<ContentReference>, Failure>(
        Failure.fromException(
          e,
          stackTrace: st,
          code: 'home_hero_error',
          context: <String, Object?>{'operation': 'getHeroItems'},
        ),
      );
    }
  }

  @override
  Future<List<MovieSummary>> getContinueWatchingMovies() async {
    final items = await _continueWatching();
    return items
        .where((e) => e.type == ContentType.movie && e.poster != null)
        .map(
          (e) => MovieSummary(
            id: MovieId(e.contentId),
            title: MediaTitle(e.title),
            poster: e.poster!,
            backdrop: e.backdrop,
            releaseYear: e.year,
            tags: const [],
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<TvShowSummary>> getContinueWatchingShows() async {
    final items = await _continueWatching();
    return items
        .where((e) => e.type == ContentType.series && e.poster != null)
        .map(
          (e) => TvShowSummary(
            id: SeriesId(e.contentId),
            title: MediaTitle(e.seriesTitle ?? e.title),
            poster: e.poster!,
            backdrop: e.backdrop,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<Result<Map<String, List<ContentReference>>, Failure>>
      getIptvCategoryLists({int? itemLimitPerPlaylist}) async {
    try {
      _enrichedKeys.clear();
      final lists = await _catalogReader.listCategoryLists(
        activeSourceIds: _appState.preferredIptvSourceIds,
        itemLimitPerPlaylist: itemLimitPerPlaylist ?? HomeConstants.iptvSectionPreviewLimit,
      );
      return Ok<Map<String, List<ContentReference>>, Failure>(lists);
    } catch (e, st) {
      debugPrint(
        '[HomeFeedRepositoryImpl] getIptvCategoryLists error: $e\n$st',
      );
      return Err<Map<String, List<ContentReference>>, Failure>(
        Failure.fromException(
          e,
          stackTrace: st,
          code: 'home_iptv_error',
          context: <String, Object?>{'operation': 'getIptvCategoryLists'},
        ),
      );
    }
  }

  @override
  Future<ContentReference> enrichReference(
    ContentReference ref, {
    CancelToken? cancelToken,
  }) async {
    int? idNum = int.tryParse(ref.id);
    final bool isSeries = ref.type == ContentType.series;

    final key = '${ref.type.name}|${ref.id}';
    if (_enrichedKeys.contains(key)) return ref;

    if (idNum == null) {
      try {
        if (isSeries) {
          final results = await _tvRemote.searchShows(
            ref.title.value,
            cancelToken: cancelToken,
          );
          idNum = results.isNotEmpty ? results.first.id : null;
        } else {
          final results = await _moviesRemote.searchMovies(
            ref.title.value,
            cancelToken: cancelToken,
          );
          idNum = results.isNotEmpty ? results.first.id : null;
        }
      } catch (_) {}
    }
    if (idNum == null) return ref;

    final languageCode = _languageCode;

    try {
      if (isSeries) {
        Map<String, dynamic>? cached = await _tmdbCache.getTvDetail(
          idNum,
          language: languageCode,
          policyOverride: const CachePolicy(ttl: Duration(days: 3)),
        );
        if (cached == null) {
          final dto = await _tvRemote.fetchShowLite(
            idNum,
            language: languageCode,
            cancelToken: cancelToken,
          );
          cached = dto.toCache();
          await _tmdbCache.putTvDetail(
            idNum,
            cached,
            language: languageCode,
          );
        }

        final String? posterPath =
            TmdbImageSelectorService.selectPosterPath(
              (cached['images']?['posters'] as List<dynamic>?) ??
                  const <dynamic>[],
            ) ??
            cached['poster_path']?.toString();

        final String? tmdbTitle =
            (cached['name']?.toString() ?? cached['original_name']?.toString());

        final result = ContentReference(
          id: ref.id,
          title: MediaTitle(
            (tmdbTitle != null && tmdbTitle.isNotEmpty)
                ? tmdbTitle
                : ref.title.value,
          ),
          type: ref.type,
          poster: _images.poster(posterPath) ?? ref.poster,
          year: _parseYear(cached['first_air_date']?.toString()) ?? ref.year,
          rating: (cached['vote_average'] as num?)?.toDouble() ?? ref.rating,
        );

        _enrichedKeys.add(key);
        return result;
      } else {
        Map<String, dynamic>? cached = await _tmdbCache.getMovieDetail(
          idNum,
          language: languageCode,
          policyOverride: const CachePolicy(ttl: Duration(days: 3)),
        );
        if (cached == null) {
          final dto = await _moviesRemote.fetchMovieLite(
            idNum,
            language: languageCode,
            cancelToken: cancelToken,
          );
          cached = dto.toCache();
          await _tmdbCache.putMovieDetail(
            idNum,
            cached,
            language: languageCode,
          );
        }

        final String? posterPath =
            TmdbImageSelectorService.selectPosterPath(
              (cached['images']?['posters'] as List<dynamic>?) ??
                  const <dynamic>[],
            ) ??
            cached['poster_path']?.toString();

        final String? tmdbTitle =
            (cached['title']?.toString() ??
                cached['original_title']?.toString());

        final result = ContentReference(
          id: ref.id,
          title: MediaTitle(
            (tmdbTitle != null && tmdbTitle.isNotEmpty)
                ? tmdbTitle
                : ref.title.value,
          ),
          type: ref.type,
          poster: _images.poster(posterPath) ?? ref.poster,
          year: _parseYear(cached['release_date']?.toString()) ?? ref.year,
          rating: (cached['vote_average'] as num?)?.toDouble() ?? ref.rating,
        );

        _enrichedKeys.add(key);
        return result;
      }
    } catch (e, st) {
      assert(() {
        debugPrint('[HomeFeedRepositoryImpl] enrichReference error: $e\n$st');
        return true;
      }());
      return ref;
    }
  }

  Future<Set<int>> _collectAvailableMovieTmdbIds() async {
    return _catalogReader.getAvailableTmdbIds(
      type: XtreamPlaylistItemType.movie,
      activeSourceIds: _appState.preferredIptvSourceIds,
    );
  }

  Future<Set<int>> _collectAvailableSeriesTmdbIds() async {
    return _catalogReader.getAvailableTmdbIds(
      type: XtreamPlaylistItemType.series,
      activeSourceIds: _appState.preferredIptvSourceIds,
    );
  }

  Future<List<_MovieLiteDto>> _fetchTrendingMoviesPage(int page) async {
    final languageCode = _languageCode;

    try {
      final List<dynamic> res = await _moviesRemote.fetchTrendingMovies(
        window: _trendingWindow,
        page: page,
        language: languageCode,
      );
      return res
          .map(_MovieLiteDto.tryParse)
          .whereType<_MovieLiteDto>()
          .toList(growable: false);
    } catch (e, st) {
      assert(() {
        debugPrint(
          '[HomeFeedRepositoryImpl] fetchTrendingMovies(page:$page) error: $e\n$st',
        );
        return true;
      }());
      if (page == 1) {
        try {
          final List<dynamic> res = await _moviesRemote.fetchTrendingMovies(
            window: _trendingWindow,
            language: languageCode,
          );
          return res
              .map(_MovieLiteDto.tryParse)
              .whereType<_MovieLiteDto>()
              .toList(growable: false);
        } catch (_) {}
      }
      return const <_MovieLiteDto>[];
    }
  }

  Future<List<_TvLiteDto>> _fetchTrendingShowsPage(int page) async {
    final languageCode = _languageCode;

    try {
      final List<dynamic> res = await _tvRemote.fetchTrendingShows(
        window: _trendingWindow,
        page: page,
        language: languageCode,
      );
      return res
          .map(_TvLiteDto.tryParse)
          .whereType<_TvLiteDto>()
          .toList(growable: false);
    } catch (e, st) {
      assert(() {
        debugPrint(
          '[HomeFeedRepositoryImpl] fetchTrendingShows(page:$page) error: $e\n$st',
        );
        return true;
      }());
      if (page == 1) {
        try {
          final List<dynamic> res = await _tvRemote.fetchTrendingShows(
            window: _trendingWindow,
            language: languageCode,
          );
          return res
              .map(_TvLiteDto.tryParse)
              .whereType<_TvLiteDto>()
              .toList(growable: false);
        } catch (_) {}
      }
      return const <_TvLiteDto>[];
    }
  }

  List<ContentReference> _mapMovieDtosToHeroCandidates(List<_MovieLiteDto> dtos) {
    final result = <ContentReference>[];
    for (final dto in dtos) {
      final Uri? poster = _images.poster(dto.posterPath);
      final Uri? backdrop = _images.backdrop(dto.backdropPath);

      final Uri? chosenPoster = poster ?? backdrop;
      if (chosenPoster == null) {
        continue;
      }

      result.add(
        ContentReference(
          id: dto.id.toString(),
          title: MediaTitle(dto.title),
          type: ContentType.movie,
          poster: chosenPoster,
          year: _parseYear(dto.releaseDate),
          rating: dto.voteAverage,
        ),
      );
    }
    return result;
  }

  List<ContentReference> _mapTvDtosToHeroCandidates(List<_TvLiteDto> dtos) {
    final result = <ContentReference>[];
    for (final dto in dtos) {
      final Uri? poster = _images.poster(dto.posterPath);
      final Uri? backdrop = _images.backdrop(dto.backdropPath);

      final Uri? chosenPoster = poster ?? backdrop;
      if (chosenPoster == null) {
        continue;
      }

      result.add(
        ContentReference(
          id: dto.id.toString(),
          title: MediaTitle(dto.name),
          type: ContentType.series,
          poster: chosenPoster,
          year: _parseYear(dto.firstAirDate),
          rating: dto.voteAverage,
        ),
      );
    }
    return result;
  }

  List<ContentReference> _interleaveMoviesAndSeries(
    List<ContentReference> movies,
    List<ContentReference> series,
  ) {
    if (movies.isEmpty) return series;
    if (series.isEmpty) return movies;

    final out = <ContentReference>[];
    final maxLen = (movies.length > series.length) ? movies.length : series.length;
    for (var i = 0; i < maxLen; i++) {
      if (i < movies.length) out.add(movies[i]);
      if (i < series.length) out.add(series[i]);
    }
    return out;
  }

  @override
  Future<Result<List<ContentReference>, Failure>> getTrendingMoviesPage(int page) async {
    try {
      final pageDtos = await _fetchTrendingMoviesPage(page);
      final movies = _mapMovieDtosToHeroCandidates(pageDtos);
      return Ok<List<ContentReference>, Failure>(movies);
    } catch (e, st) {
      debugPrint('[HomeFeedRepositoryImpl] getTrendingMoviesPage error: $e\n$st');
      return Err<List<ContentReference>, Failure>(
        Failure.fromException(
          e,
          stackTrace: st,
          code: 'home_trending_movies_error',
          context: <String, Object?>{'operation': 'getTrendingMoviesPage', 'page': page},
        ),
      );
    }
  }

  @override
  Future<Result<List<ContentReference>, Failure>> getTrendingSeriesPage(int page) async {
    try {
      final pageDtos = await _fetchTrendingShowsPage(page);
      final series = _mapTvDtosToHeroCandidates(pageDtos);
      return Ok<List<ContentReference>, Failure>(series);
    } catch (e, st) {
      debugPrint('[HomeFeedRepositoryImpl] getTrendingSeriesPage error: $e\n$st');
      return Err<List<ContentReference>, Failure>(
        Failure.fromException(
          e,
          stackTrace: st,
          code: 'home_trending_series_error',
          context: <String, Object?>{'operation': 'getTrendingSeriesPage', 'page': page},
        ),
      );
    }
  }

  List<T> _takeFirst<T>(List<T> list, int n) {
    if (list.length <= n) return list;
    return list.sublist(0, n);
  }

  int? _parseYear(String? raw) {
    if (raw == null || raw.isEmpty || raw.length < 4) return null;
    return int.tryParse(raw.substring(0, 4));
  }
}

class _MovieLiteDto {
  const _MovieLiteDto({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.voteAverage,
  });

  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double? voteAverage;

  static _MovieLiteDto? tryParse(dynamic e) {
    if (e is Map<String, dynamic>) {
      final int? id = (e['id'] as num?)?.toInt();
      final String? title = (e['title'] ?? e['original_title'])?.toString();
      if (id == null || title == null) return null;
      return _MovieLiteDto(
        id: id,
        title: title,
        posterPath: e['poster_path']?.toString(),
        backdropPath: e['backdrop_path']?.toString(),
        releaseDate: e['release_date']?.toString(),
        voteAverage: (e['vote_average'] as num?)?.toDouble(),
      );
    }
    return null;
  }
}

class _TvLiteDto {
  const _TvLiteDto({
    required this.id,
    required this.name,
    this.posterPath,
    this.backdropPath,
    this.firstAirDate,
    this.voteAverage,
  });

  final int id;
  final String name;
  final String? posterPath;
  final String? backdropPath;
  final String? firstAirDate;
  final double? voteAverage;

  static _TvLiteDto? tryParse(dynamic e) {
    if (e is Map<String, dynamic>) {
      final int? id = (e['id'] as num?)?.toInt();
      final String? name = (e['name'] ?? e['original_name'])?.toString();
      if (id == null || name == null) return null;
      return _TvLiteDto(
        id: id,
        name: name,
        posterPath: e['poster_path']?.toString(),
        backdropPath: e['backdrop_path']?.toString(),
        firstAirDate: e['first_air_date']?.toString(),
        voteAverage: (e['vote_average'] as num?)?.toDouble(),
      );
    }
    return null;
  }
}
