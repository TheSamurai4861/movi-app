import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';
import 'package:movi/src/features/tv/data/datasources/tv_local_data_source.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_detail_dto.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_season_detail_dto.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/shared/data/services/tmdb_cache_data_source.dart';
import 'package:movi/src/shared/data/services/tmdb_detail_cache_data_source.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/shared/domain/services/tmdb_image_selector_service.dart';
import 'package:movi/src/shared/domain/value_objects/content_rating.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/value_objects/synopsis.dart';

class TvRepositoryImpl implements TvRepository {
  @visibleForTesting
  static bool cacheSatisfiesFullShowLoad(TmdbTvDetailDto cached) {
    final hasLogoData = cached.logoPath != null || cached.logoPngExhausted;
    final hasCastData = cached.cast.isNotEmpty || cached.castExhausted;
    return hasLogoData && hasCastData;
  }

  TvRepositoryImpl(
    this._remote,
    this._images,
    this._watchlist,
    this._local,
    this._continueWatching,
    this._appState,
    this._tmdbCache, {
    required TmdbDetailCacheDataSource detailCache,
    String? userId,
  }) : _detailCache = detailCache,
       _userId = userId ?? 'default';

  final TmdbTvRemoteDataSource _remote;
  final TmdbImageResolver _images;
  final WatchlistLocalRepository _watchlist;
  final TvLocalDataSource _local;
  final ContinueWatchingLocalRepository _continueWatching;
  final AppStateController _appState;
  final TmdbCacheDataSource _tmdbCache;
  final TmdbDetailCacheDataSource _detailCache;
  final String _userId;
  final Map<String, Future<void>> _backgroundRefreshes =
      <String, Future<void>>{};

  static const int _maxConcurrentSeasons = 4;

  String get _languageCode {
    final locale = _appState.preferredLocale;
    final country = locale.countryCode;
    if (country == null || country.isEmpty) {
      return locale.languageCode;
    }
    return '${locale.languageCode}-$country';
  }

  int _extractNumericId(SeriesId id) {
    final value = id.value;
    if (value.startsWith('xtream:')) {
      return int.parse(value.substring(7));
    }
    return int.parse(value);
  }

  @override
  Future<TvShow> getShow(SeriesId id) async {
    final showId = _extractNumericId(id);
    final detail = await _loadShowDtoFull(showId);
    final seasonDetails = await _loadSeasonsBatched(showId, detail.seasons);
    return _mapShow(detail, seasonDetails);
  }

  @override
  Future<TvShow> getShowLite(SeriesId id) async {
    final showId = _extractNumericId(id);
    final detail = await _loadShowDtoLite(showId);
    return _mapShowLite(detail);
  }

  @override
  Future<List<Season>> getSeasons(SeriesId id) async {
    final showId = _extractNumericId(id);
    final detail = await _loadShowDtoFull(showId);
    final seasonDetails = await _loadSeasonsBatched(showId, detail.seasons);
    return _mapSeasons(detail.seasons, seasonDetails);
  }

  @override
  Future<List<Episode>> getEpisodes(SeriesId id, SeasonId seasonId) async {
    final showId = _extractNumericId(id);
    final seasonNumber = int.parse(seasonId.value);
    final season = await _loadSeasonDto(showId, seasonNumber);
    return _mapEpisodes(season);
  }

  @override
  Future<List<TvShowSummary>> getFeaturedShows() async {
    final popular = await _remote.fetchPopular(language: _languageCode);
    return popular
        .map(_mapSummary)
        .whereType<TvShowSummary>()
        .toList(growable: false);
  }

  @override
  Future<List<TvShowSummary>> getUserWatchlist() async {
    final entries = await _watchlist.readAll(ContentType.series);
    return entries
        .where((e) => e.poster != null)
        .map(
          (e) => TvShowSummary(
            id: SeriesId(e.contentId),
            tmdbId: int.tryParse(e.contentId),
            title: MediaTitle(e.title),
            poster: e.poster!,
            backdrop: null,
            seasonCount: null,
            status: null,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<TvShowSummary>> getContinueWatching() async {
    final entries = await _continueWatching.readAll(ContentType.series);
    return entries
        .where((e) => e.poster != null)
        .map(
          (e) => TvShowSummary(
            id: SeriesId(e.contentId),
            tmdbId: int.tryParse(e.contentId),
            title: MediaTitle(e.title),
            poster: e.poster!,
            backdrop: null,
            seasonCount: null,
            status: null,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<TvShowSummary>> searchShows(String query) async {
    final results = await _remote.searchShows(query, language: _languageCode);
    return results
        .map(_mapSummary)
        .whereType<TvShowSummary>()
        .toList(growable: false);
  }

  @override
  Future<bool> isInWatchlist(SeriesId id) =>
      _watchlist.exists(id.value, ContentType.series, userId: _userId);

  @override
  Future<void> refreshMetadata(SeriesId id) async {
    final showId = _extractNumericId(id);
    await _local.clearShowDetail(showId);
    await _detailCache.clearTvShow(showId, language: _languageCode);
  }

  @override
  Future<void> setWatchlist(SeriesId id, {required bool saved}) async {
    if (saved) {
      final show = await getShow(id);
      await _watchlist.upsert(
        WatchlistEntry(
          contentId: id.value,
          type: ContentType.series,
          title: show.title.value,
          poster: show.poster,
          addedAt: DateTime.now(),
          userId: _userId,
        ),
      );
    } else {
      await _watchlist.remove(id.value, ContentType.series, userId: _userId);
    }
  }

  Future<TmdbTvDetailDto?> _tryMergeLogoFromHeroCache(
    int showId,
    TmdbTvDetailDto cached,
  ) async {
    if (cached.logoPath != null) return null;
    try {
      final heroJson = await _tmdbCache.getTvDetail(
        showId,
        language: _languageCode,
      );
      if (heroJson == null) return null;
      final images = heroJson['images'];
      if (images is! Map) return null;
      final logosRaw = images['logos'];
      if (logosRaw is! List || logosRaw.isEmpty) return null;
      final pref = _languageCode.split('-').first.toLowerCase().trim();
      final path = TmdbImageSelectorService.selectLogoPath(
        logosRaw,
        preferredLang: pref.isEmpty ? null : pref,
      );
      if (path == null) return null;
      return cached.copyWith(logoPath: path);
    } catch (_) {
      return null;
    }
  }

  Future<TmdbTvDetailDto> _loadShowDtoLite(int showId) async {
    final logger = sl<AppLogger>();
    final cachedLite = await _detailCache.getCachedTvDetailLite(
      showId: showId,
      language: _languageCode,
    );
    if (cachedLite.isFresh) {
      _logCache(logger, 'tv_detail_lite', 'cache_hit_fresh', showId);
      return cachedLite.value!;
    }
    if (cachedLite.isStale) {
      _logCache(logger, 'tv_detail_lite', 'cache_hit_stale', showId);
      _scheduleBackgroundShowRefresh(showId, full: false);
      return cachedLite.value!;
    }

    final cachedFull = await _detailCache.getCachedTvDetailFull(
      showId: showId,
      language: _languageCode,
    );
    if (cachedFull.value != null) {
      _logCache(
        logger,
        'tv_detail_lite',
        cachedFull.isFresh ? 'cache_hit_fresh' : 'cache_hit_stale',
        showId,
        source: 'full_cache',
      );
      if (cachedFull.isStale) {
        _scheduleBackgroundShowRefresh(showId, full: false);
      }
      await _persistShowDetailLite(cachedFull.value!);
      return cachedFull.value!;
    }

    final legacy = await _local.getShowDetail(showId);
    if (legacy != null) {
      _logCache(
        logger,
        'tv_detail_lite',
        'cache_hit_fresh',
        showId,
        source: 'legacy',
      );
      await _persistShowDetailLite(legacy);
      return legacy;
    }

    _logCache(logger, 'tv_detail_lite', 'cache_miss', showId);
    return _fetchAndPersistShowLite(showId);
  }

  Future<TmdbTvDetailDto> _loadShowDtoFull(int showId) async {
    final logger = sl<AppLogger>();
    final cached = await _detailCache.getCachedTvDetailFull(
      showId: showId,
      language: _languageCode,
    );
    if (cached.isFresh) {
      final merged = await _tryMergeLogoFromHeroCache(showId, cached.value!);
      if (merged != null) {
        await _persistShowDetailLite(merged);
        await _persistShowDetailFull(merged);
        _logCache(
          logger,
          'tv_detail_full',
          'cache_hit_fresh',
          showId,
          source: 'full_cache_logo_merged',
        );
        return merged;
      }
      _logCache(logger, 'tv_detail_full', 'cache_hit_fresh', showId);
      return cached.value!;
    }
    if (cached.isStale) {
      final merged = await _tryMergeLogoFromHeroCache(showId, cached.value!);
      if (merged != null) {
        await _persistShowDetailLite(merged);
        await _persistShowDetailFull(merged);
        _logCache(
          logger,
          'tv_detail_full',
          'cache_hit_stale',
          showId,
          source: 'full_cache_logo_merged',
        );
        _scheduleBackgroundShowRefresh(showId, full: true);
        return merged;
      }
      _logCache(logger, 'tv_detail_full', 'cache_hit_stale', showId);
      _scheduleBackgroundShowRefresh(showId, full: true);
      return cached.value!;
    }

    TmdbTvDetailDto? legacy = await _local.getShowDetail(showId);
    if (legacy != null) {
      final merged = await _tryMergeLogoFromHeroCache(showId, legacy);
      if (merged != null) {
        legacy = merged;
      }
      if (cacheSatisfiesFullShowLoad(legacy)) {
        _logCache(
          logger,
          'tv_detail_full',
          'cache_hit_fresh',
          showId,
          source: 'legacy',
        );
        await _persistShowDetailLite(legacy);
        await _persistShowDetailFull(legacy);
        return legacy;
      }
    }

    _logCache(logger, 'tv_detail_full', 'cache_miss', showId);
    return _fetchAndPersistShowFull(showId);
  }

  Future<TmdbTvDetailDto> _fetchAndPersistShowLite(int showId) async {
    final logger = sl<AppLogger>();
    final token = CancelToken();
    final start = DateTime.now();
    final remote = await _remote
        .fetchShowWithImages(
          showId,
          language: _languageCode,
          cancelToken: token,
        )
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            if (!token.isCancelled) {
              token.cancel('Timeout after 10s');
            }
            throw TimeoutException('Timeout fetchShowWithImages after 10s');
          },
        );
    await _persistShowDetailLite(remote);
    logger.debug(
      'background_refresh_completed resource=tv_detail_lite showId=$showId lang=$_languageCode durationMs=${DateTime.now().difference(start).inMilliseconds}',
      category: 'tv_repository',
    );
    return remote;
  }

  Future<TmdbTvDetailDto> _fetchAndPersistShowFull(int showId) async {
    final logger = sl<AppLogger>();
    final token = CancelToken();
    final start = DateTime.now();
    final remote = await _remote
        .fetchShowFull(showId, language: _languageCode, cancelToken: token)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            if (!token.isCancelled) {
              token.cancel('Timeout after 10s');
            }
            throw TimeoutException('Timeout fetchShowFull after 10s');
          },
        );
    final toPersist = remote.copyWith(
      logoPngExhausted: remote.logoPath == null
          ? true
          : remote.logoPngExhausted,
      castExhausted: remote.cast.isEmpty ? true : remote.castExhausted,
    );
    await _persistShowDetailLite(toPersist);
    await _persistShowDetailFull(toPersist);
    logger.debug(
      'background_refresh_completed resource=tv_detail_full showId=$showId lang=$_languageCode durationMs=${DateTime.now().difference(start).inMilliseconds}',
      category: 'tv_repository',
    );
    return toPersist;
  }

  Future<void> _persistShowDetailLite(TmdbTvDetailDto dto) async {
    await _detailCache.putTvDetailLite(dto, language: _languageCode);
    await _local.saveShowDetail(dto);
  }

  Future<void> _persistShowDetailFull(TmdbTvDetailDto dto) async {
    await _detailCache.putTvDetailFull(dto, language: _languageCode);
    await _local.saveShowDetail(dto);
  }

  void _scheduleBackgroundShowRefresh(int showId, {required bool full}) {
    final logger = sl<AppLogger>();
    final resource = full ? 'tv_detail_full' : 'tv_detail_lite';
    final key = '$resource:$showId:$_languageCode';
    if (_backgroundRefreshes.containsKey(key)) return;

    _logCache(logger, resource, 'background_refresh_started', showId);
    final future = () async {
      try {
        if (full) {
          await _fetchAndPersistShowFull(showId);
        } else {
          await _fetchAndPersistShowLite(showId);
        }
      } catch (error, stackTrace) {
        logger.log(
          LogLevel.warn,
          'background_refresh_failed resource=$resource showId=$showId lang=$_languageCode',
          category: 'tv_repository',
          error: error,
          stackTrace: stackTrace,
        );
      } finally {
        _backgroundRefreshes.remove(key);
      }
    }();
    _backgroundRefreshes[key] = future;
    unawaited(future);
  }

  Future<Map<int, TmdbTvSeasonDetailDto>> _loadSeasonsBatched(
    int showId,
    List<TmdbTvSeasonDto> seasons,
  ) async {
    final filtered = seasons.where((s) => s.seasonNumber >= 0).toList()
      ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));

    final results = <int, TmdbTvSeasonDetailDto>{};
    List<Future<void>> batch = <Future<void>>[];
    for (final season in filtered) {
      batch.add(() async {
        try {
          final dto = await _loadSeasonDto(showId, season.seasonNumber);
          results[season.seasonNumber] = dto;
        } catch (_) {}
      }());
      if (batch.length >= _maxConcurrentSeasons) {
        await Future.wait(batch);
        batch = <Future<void>>[];
      }
    }
    if (batch.isNotEmpty) {
      await Future.wait(batch);
    }

    for (final season in filtered) {
      results.putIfAbsent(
        season.seasonNumber,
        () => _emptySeasonDetail(season),
      );
    }
    return results;
  }

  Future<TmdbTvSeasonDetailDto> _loadSeasonDto(
    int showId,
    int seasonNumber,
  ) async {
    final logger = sl<AppLogger>();
    final cached = await _detailCache.getCachedTvSeasonDetail(
      showId: showId,
      seasonNumber: seasonNumber,
      language: _languageCode,
    );
    if (cached.isFresh) {
      _logCache(
        logger,
        'tv_season_detail',
        'cache_hit_fresh',
        showId,
        seasonNumber: seasonNumber,
      );
      return cached.value!;
    }
    if (cached.isStale) {
      _logCache(
        logger,
        'tv_season_detail',
        'cache_hit_stale',
        showId,
        seasonNumber: seasonNumber,
      );
      _scheduleBackgroundSeasonRefresh(showId, seasonNumber);
      return cached.value!;
    }

    final legacy = await _local.getSeason(showId, seasonNumber);
    if (legacy != null) {
      _logCache(
        logger,
        'tv_season_detail',
        'cache_hit_fresh',
        showId,
        seasonNumber: seasonNumber,
        source: 'legacy',
      );
      await _persistSeason(showId, seasonNumber, legacy);
      return legacy;
    }

    _logCache(
      logger,
      'tv_season_detail',
      'cache_miss',
      showId,
      seasonNumber: seasonNumber,
    );
    return _fetchAndPersistSeason(showId, seasonNumber);
  }

  Future<TmdbTvSeasonDetailDto> _fetchAndPersistSeason(
    int showId,
    int seasonNumber,
  ) async {
    final token = CancelToken();
    final remote = await _remote
        .fetchSeason(
          showId,
          seasonNumber,
          language: _languageCode,
          cancelToken: token,
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            if (!token.isCancelled) {
              token.cancel('Timeout after 15s');
            }
            throw TimeoutException('Timeout fetchSeason after 15s');
          },
        );
    await _persistSeason(showId, seasonNumber, remote);
    return remote;
  }

  Future<void> _persistSeason(
    int showId,
    int seasonNumber,
    TmdbTvSeasonDetailDto dto,
  ) async {
    await _detailCache.putTvSeasonDetail(
      dto,
      showId: showId,
      seasonNumber: seasonNumber,
      language: _languageCode,
    );
    await _local.saveSeason(showId, seasonNumber, dto);
  }

  void _scheduleBackgroundSeasonRefresh(int showId, int seasonNumber) {
    final logger = sl<AppLogger>();
    final key = 'tv_season_detail:$showId:$seasonNumber:$_languageCode';
    if (_backgroundRefreshes.containsKey(key)) return;
    _logCache(
      logger,
      'tv_season_detail',
      'background_refresh_started',
      showId,
      seasonNumber: seasonNumber,
    );
    final future = () async {
      try {
        await _fetchAndPersistSeason(showId, seasonNumber);
        _logCache(
          logger,
          'tv_season_detail',
          'background_refresh_completed',
          showId,
          seasonNumber: seasonNumber,
        );
      } catch (error, stackTrace) {
        logger.log(
          LogLevel.warn,
          'background_refresh_failed resource=tv_season_detail showId=$showId seasonNumber=$seasonNumber lang=$_languageCode',
          category: 'tv_repository',
          error: error,
          stackTrace: stackTrace,
        );
      } finally {
        _backgroundRefreshes.remove(key);
      }
    }();
    _backgroundRefreshes[key] = future;
    unawaited(future);
  }

  void _logCache(
    AppLogger logger,
    String resource,
    String event,
    int showId, {
    int? seasonNumber,
    String? source,
  }) {
    logger.debug(
      '$event resource=$resource showId=$showId'
      '${seasonNumber == null ? '' : ' seasonNumber=$seasonNumber'}'
      ' lang=$_languageCode${source == null ? '' : ' source=$source'}',
      category: 'tv_repository',
    );
  }

  TvShow _mapShow(
    TmdbTvDetailDto dto,
    Map<int, TmdbTvSeasonDetailDto> seasonDetails,
  ) {
    final poster = _images.poster(
      dto.posterPath ?? dto.posterBackground,
      size: 'w780',
    );

    if (poster == null) {
      throw StateError('TV show ${dto.id} missing poster');
    }

    final posterBackground =
        _images.poster(dto.posterBackground, size: 'w780') ?? poster;

    final backdrop = _images.backdrop(dto.backdropPath, size: 'w1280');
    final logo = _images.logo(dto.logoPath, size: 'w500');

    return TvShow(
      id: SeriesId(dto.id.toString()),
      tmdbId: dto.id,
      title: MediaTitle(dto.name),
      synopsis: Synopsis(dto.overview),
      logo: logo,
      poster: poster,
      posterBackground: posterBackground,
      backdrop: backdrop,
      firstAirDate: _parseDate(dto.firstAirDate),
      lastAirDate: _parseDate(dto.lastAirDate),
      status: _mapStatus(dto.status),
      rating: _mapRating(dto.voteAverage),
      voteAverage: dto.voteAverage,
      genres: dto.genres,
      cast: dto.cast.take(10).map(_mapCast).toList(growable: false),
      creators: dto.creators
          .map(
            (c) => PersonSummary(
              id: PersonId(c.id.toString()),
              tmdbId: c.id,
              name: c.name,
            ),
          )
          .toList(growable: false),
      seasons: _mapSeasons(dto.seasons, seasonDetails),
    );
  }

  TvShow _mapShowLite(TmdbTvDetailDto dto) {
    final poster = _images.poster(
      dto.posterPath ?? dto.posterBackground,
      size: 'w780',
    );

    if (poster == null) {
      throw StateError('TV show ${dto.id} missing poster');
    }

    final posterBackground =
        _images.poster(dto.posterBackground, size: 'w780') ?? poster;

    final backdrop = _images.backdrop(dto.backdropPath, size: 'w1280');
    final logo = _images.logo(dto.logoPath, size: 'w500');

    return TvShow(
      id: SeriesId(dto.id.toString()),
      tmdbId: dto.id,
      title: MediaTitle(dto.name),
      synopsis: Synopsis(dto.overview),
      logo: logo,
      poster: poster,
      posterBackground: posterBackground,
      backdrop: backdrop,
      firstAirDate: _parseDate(dto.firstAirDate),
      lastAirDate: _parseDate(dto.lastAirDate),
      status: _mapStatus(dto.status),
      rating: _mapRating(dto.voteAverage),
      voteAverage: dto.voteAverage,
      genres: dto.genres,
      cast: dto.cast.take(10).map(_mapCast).toList(growable: false),
      creators: dto.creators
          .map(
            (c) => PersonSummary(
              id: PersonId(c.id.toString()),
              tmdbId: c.id,
              name: c.name,
            ),
          )
          .toList(growable: false),
      seasons: dto.seasons
          .where((s) => s.seasonNumber >= 0)
          .map(
            (season) => Season(
              id: SeasonId(season.seasonNumber.toString()),
              seasonNumber: season.seasonNumber,
              title: MediaTitle(season.name),
              overview: season.overview.isEmpty
                  ? null
                  : Synopsis(season.overview),
              poster: _images.poster(season.posterPath),
              episodes: const [],
              airDate: _parseDate(season.airDate),
            ),
          )
          .toList(growable: false),
    );
  }

  List<Season> _mapSeasons(
    List<TmdbTvSeasonDto> seasons,
    Map<int, TmdbTvSeasonDetailDto> details,
  ) {
    return seasons
        .map((season) {
          final detail =
              details[season.seasonNumber] ?? _emptySeasonDetail(season);
          return Season(
            id: SeasonId(season.seasonNumber.toString()),
            seasonNumber: season.seasonNumber,
            title: MediaTitle(season.name),
            overview: season.overview.isEmpty
                ? null
                : Synopsis(season.overview),
            poster: _images.poster(season.posterPath),
            episodes: _mapEpisodes(detail),
            airDate: _parseDate(season.airDate),
          );
        })
        .toList(growable: false);
  }

  List<Episode> _mapEpisodes(TmdbTvSeasonDetailDto detail) {
    return detail.episodes
        .map(
          (ep) => Episode(
            id: EpisodeId(ep.id.toString()),
            episodeNumber: ep.episodeNumber,
            title: MediaTitle(ep.name),
            overview: ep.overview.isEmpty ? null : Synopsis(ep.overview),
            runtime: ep.runtime != null ? Duration(minutes: ep.runtime!) : null,
            airDate: _parseDate(ep.airDate),
            still: _images.still(ep.stillPath),
            voteAverage: ep.voteAverage,
          ),
        )
        .toList(growable: false);
  }

  TmdbTvSeasonDetailDto _emptySeasonDetail(TmdbTvSeasonDto season) {
    return TmdbTvSeasonDetailDto(
      id: season.id,
      name: season.name,
      airDate: season.airDate,
      episodes: const [],
    );
  }

  TvShowSummary? _mapSummary(TmdbTvSummaryDto dto) {
    final poster = _images.poster(dto.posterPath, size: 'w342');
    if (poster == null) return null;
    return TvShowSummary(
      id: SeriesId(dto.id.toString()),
      tmdbId: dto.id,
      title: MediaTitle(dto.name),
      poster: poster,
      backdrop: _images.backdrop(dto.backdropPath),
      seasonCount: null,
      status: null,
    );
  }

  PersonSummary _mapCast(TmdbTvCastDto cast) {
    return PersonSummary(
      id: PersonId(cast.id.toString()),
      tmdbId: cast.id,
      name: cast.name,
      role: cast.character,
      photo: _images.poster(cast.profilePath),
    );
  }

  DateTime? _parseDate(String? date) =>
      (date == null || date.isEmpty) ? null : DateTime.tryParse(date);

  SeriesStatus? _mapStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'ended':
        return SeriesStatus.ended;
      case 'returning series':
      case 'in production':
        return SeriesStatus.ongoing;
      case 'canceled':
        return SeriesStatus.hiatus;
      default:
        return null;
    }
  }

  ContentRating? _mapRating(double? voteAverage) {
    if (voteAverage == null) return null;
    if (voteAverage >= 8.0) return ContentRating.pg13;
    if (voteAverage >= 5.0) return ContentRating.pg;
    return ContentRating.unrated;
  }
}
