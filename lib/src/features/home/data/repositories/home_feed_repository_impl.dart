/* lib/src/features/home/data/repositories/home_feed_repository_impl.dart */
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:movi/src/features/iptv/application/iptv_catalog_reader.dart';
import 'package:movi/src/core/state/app_state_controller.dart';

import 'package:movi/src/shared/data/services/tmdb_cache_data_source.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/core/storage/services/cache_policy.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
import 'package:movi/src/features/movie/movie.dart';

import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';
import 'package:movi/src/features/tv/tv.dart';

import 'package:movi/src/features/home/domain/repositories/home_feed_repository.dart';

class HomeFeedRepositoryImpl implements HomeFeedRepository {
  HomeFeedRepositoryImpl(
    this._moviesRemote,
    this._tvRemote,
    this._catalogReader,
    this._movieRepository,
    this._tvRepository,
    this._images,
    this._appState,
    this._tmdbCache,
  );

  final TmdbMovieRemoteDataSource _moviesRemote;
  final TmdbTvRemoteDataSource _tvRemote;
  final IptvCatalogReader _catalogReader;
  final MovieRepository _movieRepository;
  final TvRepository _tvRepository;
  final TmdbImageResolver _images;
  final AppStateController _appState;
  final TmdbCacheDataSource _tmdbCache;

  final Set<String> _enrichedIds = <String>{};

  static const String _trendingWindow = 'week';
  static const int _maxTrendingPages = 3;
  static const int _heroLimit = 20;

  @override
  Future<List<MovieSummary>> getHeroMovies() async {
    try {
      final Set<int> availableTmdb = await _collectAvailableTmdbIds();

      List<_MovieLiteDto> picked = <_MovieLiteDto>[];
      if (availableTmdb.isNotEmpty) {
        for (var page = 1; page <= _maxTrendingPages; page++) {
          final pageDtos = await _fetchTrendingMoviesPage(page);
          if (pageDtos.isEmpty) break;

          final matched = pageDtos
              .where((d) => availableTmdb.contains(d.id))
              .toList(growable: false);

          final mapped = _mapDtosToHeroCandidates(matched);
          if (mapped.isNotEmpty) {
            return _takeFirst(mapped, _heroLimit);
          }
          picked = matched;
        }
      }

      final trendPage1 = picked.isNotEmpty
          ? picked
          : await _fetchTrendingMoviesPage(1);
      final mappedTrend = _mapDtosToHeroCandidates(trendPage1);
      if (mappedTrend.isNotEmpty) {
        return _takeFirst(mappedTrend, _heroLimit);
      }

      final firstVod = await _pickFirstVodRef();
      if (firstVod != null) {
        final MovieSummary? synthetic = _fromContentReferenceToMovieSummary(
          firstVod,
        );
        if (synthetic != null) return <MovieSummary>[synthetic];
      }

      return const <MovieSummary>[];
    } catch (e, st) {
      assert(() {
        debugPrint('[HomeFeedRepositoryImpl] getHeroMovies error: $e\n$st');
        return true;
      }());
      return const <MovieSummary>[];
    }
  }

  @override
  Future<List<MovieSummary>> getContinueWatchingMovies() {
    return _movieRepository.getContinueWatching();
  }

  @override
  Future<List<TvShowSummary>> getContinueWatchingShows() {
    return _tvRepository.getContinueWatching();
  }

  @override
  Future<Map<String, List<ContentReference>>> getIptvCategoryLists() async {
    _enrichedIds.clear();
    return _catalogReader.listCategoryLists(
      activeSourceIds: _appState.activeIptvSourceIds,
    );
  }

  @override
  Future<ContentReference> enrichReference(
    ContentReference ref, {
    CancelToken? cancelToken,
  }) async {
    int? idNum = int.tryParse(ref.id);
    final bool isSeries = ref.type == ContentType.series;

    if (_enrichedIds.contains(ref.id)) return ref;

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

    try {
      if (isSeries) {
        Map<String, dynamic>? cached = await _tmdbCache.getTvDetail(
          idNum,
          language: _appState.preferredLocale,
          policyOverride: const CachePolicy(ttl: Duration(days: 3)),
        );
        if (cached == null) {
          final dto = await _tvRemote.fetchShowLite(
            idNum,
            language: _appState.preferredLocale,
            cancelToken: cancelToken,
          );
          cached = dto.toCache();
          await _tmdbCache.putTvDetail(
            idNum,
            cached,
            language: _appState.preferredLocale,
          );
        }

        final String? posterPath =
            _PosterSelector.selectBestPosterPath(
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

        _enrichedIds.add(ref.id);
        return result;
      } else {
        Map<String, dynamic>? cached = await _tmdbCache.getMovieDetail(
          idNum,
          language: _appState.preferredLocale,
          policyOverride: const CachePolicy(ttl: Duration(days: 3)),
        );
        if (cached == null) {
          final dto = await _moviesRemote.fetchMovieLite(
            idNum,
            language: _appState.preferredLocale,
            cancelToken: cancelToken,
          );
          cached = dto.toCache();
          await _tmdbCache.putMovieDetail(
            idNum,
            cached,
            language: _appState.preferredLocale,
          );
        }

        final String? posterPath =
            _PosterSelector.selectBestPosterPath(
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

        _enrichedIds.add(ref.id);
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

  Future<Set<int>> _collectAvailableTmdbIds() async {
    final refs = await _catalogReader.searchCatalog('');
    final set = <int>{};
    for (final r in refs) {
      final id = int.tryParse(r.id);
      if (id != null) set.add(id);
    }
    return set;
  }

  Future<List<_MovieLiteDto>> _fetchTrendingMoviesPage(int page) async {
    try {
      final List<dynamic> res = await _moviesRemote.fetchTrendingMovies(
        window: _trendingWindow,
        page: page,
        language: _appState.preferredLocale,
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
            language: _appState.preferredLocale,
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

  List<MovieSummary> _mapDtosToHeroCandidates(List<_MovieLiteDto> dtos) {
    final result = <MovieSummary>[];
    for (final dto in dtos) {
      final Uri? poster = _images.poster(dto.posterPath);
      final Uri? backdrop = _images.backdrop(dto.backdropPath);

      final Uri? chosenPoster = poster ?? backdrop;
      if (chosenPoster == null) {
        continue;
      }

      result.add(
        MovieSummary(
          id: MovieId(dto.id.toString()),
          tmdbId: dto.id,
          title: MediaTitle(dto.title),
          poster: chosenPoster,
          backdrop: backdrop ?? poster,
          releaseYear: _parseYear(dto.releaseDate),
        ),
      );
    }
    return result;
  }

  List<T> _takeFirst<T>(List<T> list, int n) {
    if (list.length <= n) return list;
    return list.sublist(0, n);
  }

  Future<ContentReference?> _pickFirstVodRef() async {
    final refs = await _catalogReader.searchCatalog('');
    for (final r in refs) {
      if (r.type == ContentType.movie && r.poster != null) return r;
    }
    return null;
  }

  MovieSummary? _fromContentReferenceToMovieSummary(ContentReference ref) {
    final Uri? poster = ref.poster;
    if (poster == null) return null;
    final tmdbId = int.tryParse(ref.id);
    return MovieSummary(
      id: MovieId(ref.id),
      tmdbId: tmdbId,
      title: MediaTitle(ref.title.value),
      poster: poster,
      backdrop: poster,
      releaseYear: ref.year,
    );
  }

  int? _parseYear(String? raw) {
    if (raw == null || raw.isEmpty || raw.length < 4) return null;
    return int.tryParse(raw.substring(0, 4));
  }
}

class _PosterSelector {
  const _PosterSelector._();

  static String? selectBestPosterPath(List<dynamic> posters) {
    if (posters.isEmpty) return null;

    String? pathOf(Map<String, dynamic> m) => m['file_path']?.toString();
    num scoreOf(Map<String, dynamic> m) => (m['vote_average'] as num?) ?? 0;

    final list = posters
        .whereType<Map<String, dynamic>>()
        .where((m) => m['file_path'] != null)
        .toList();
    if (list.isEmpty) return null;

    final noLang = list.where((m) => m['iso_639_1'] == null).toList()
      ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (noLang.isNotEmpty) return pathOf(noLang.first);

    final en =
        list
            .where((m) => (m['iso_639_1']?.toString().toLowerCase() == 'en'))
            .toList()
          ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (en.isNotEmpty) return pathOf(en.first);

    list.sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    return pathOf(list.first);
  }
}

class _MovieLiteDto {
  const _MovieLiteDto({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
  });

  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;

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
      );
    }
    return null;
  }
}
