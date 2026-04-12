import 'package:movi/src/core/storage/repositories/content_cache_repository.dart';
import 'package:movi/src/core/storage/services/cache_policy.dart';
import 'package:movi/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_detail_dto.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_season_detail_dto.dart';

enum CachedTmdbDetailStatus { fresh, stale, miss }

class CachedTmdbDetailValue<T> {
  const CachedTmdbDetailValue({
    required this.status,
    this.value,
    this.updatedAt,
  });

  final CachedTmdbDetailStatus status;
  final T? value;
  final DateTime? updatedAt;

  bool get isFresh => status == CachedTmdbDetailStatus.fresh && value != null;
  bool get isStale => status == CachedTmdbDetailStatus.stale && value != null;
  bool get isMiss => status == CachedTmdbDetailStatus.miss || value == null;
}

class TmdbDetailCacheDataSource {
  TmdbDetailCacheDataSource(this._cache);

  final ContentCacheRepository _cache;

  static const CachePolicy movieDetailLitePolicy = CachePolicy(
    ttl: Duration(days: 7),
  );
  static const CachePolicy movieDetailFullPolicy = CachePolicy(
    ttl: Duration(days: 7),
  );
  static const CachePolicy movieRecommendationsPolicy = CachePolicy(
    ttl: Duration(hours: 24),
  );
  static const CachePolicy tvDetailLitePolicy = CachePolicy(
    ttl: Duration(days: 7),
  );
  static const CachePolicy tvDetailFullPolicy = CachePolicy(
    ttl: Duration(days: 7),
  );
  static const CachePolicy tvSeasonActivePolicy = CachePolicy(
    ttl: Duration(hours: 24),
  );
  static const CachePolicy tvSeasonArchivePolicy = CachePolicy(
    ttl: Duration(days: 7),
  );

  Future<CachedTmdbDetailValue<TmdbMovieDetailDto>> getCachedMovieDetailLite({
    required int movieId,
    required String language,
  }) {
    return _get(
      _movieDetailLiteKey(movieId, language),
      movieDetailLitePolicy,
      TmdbMovieDetailDto.fromCache,
    );
  }

  Future<void> putMovieDetailLite(
    TmdbMovieDetailDto dto, {
    required String language,
  }) {
    return _cache.put(
      key: _movieDetailLiteKey(dto.id, language),
      type: 'tmdb_movie_detail_lite',
      payload: dto.toCache(),
    );
  }

  Future<CachedTmdbDetailValue<TmdbMovieDetailDto>> getCachedMovieDetailFull({
    required int movieId,
    required String language,
  }) {
    return _get(
      _movieDetailFullKey(movieId, language),
      movieDetailFullPolicy,
      TmdbMovieDetailDto.fromCache,
    );
  }

  Future<void> putMovieDetailFull(
    TmdbMovieDetailDto dto, {
    required String language,
  }) {
    return _cache.put(
      key: _movieDetailFullKey(dto.id, language),
      type: 'tmdb_movie_detail_full',
      payload: dto.toCache(),
    );
  }

  Future<CachedTmdbDetailValue<List<TmdbMovieSummaryDto>>>
  getCachedMovieRecommendations({
    required int movieId,
    required String language,
  }) {
    return _get(
      _movieRecommendationsKey(movieId, language),
      movieRecommendationsPolicy,
      (payload) {
        final items = payload['items'] as List<dynamic>? ?? const <dynamic>[];
        return items
            .whereType<Map<String, dynamic>>()
            .map(TmdbMovieSummaryDto.fromJson)
            .toList(growable: false);
      },
    );
  }

  Future<void> putMovieRecommendations(
    List<TmdbMovieSummaryDto> items, {
    required int movieId,
    required String language,
  }) {
    return _cache.put(
      key: _movieRecommendationsKey(movieId, language),
      type: 'tmdb_movie_recommendations',
      payload: <String, dynamic>{
        'items': items.map((item) => item.toJson()).toList(growable: false),
      },
    );
  }

  Future<CachedTmdbDetailValue<TmdbTvDetailDto>> getCachedTvDetailLite({
    required int showId,
    required String language,
  }) {
    return _get(
      _tvDetailLiteKey(showId, language),
      tvDetailLitePolicy,
      TmdbTvDetailDto.fromCache,
    );
  }

  Future<void> putTvDetailLite(
    TmdbTvDetailDto dto, {
    required String language,
  }) {
    return _cache.put(
      key: _tvDetailLiteKey(dto.id, language),
      type: 'tmdb_tv_detail_lite',
      payload: dto.toCache(),
    );
  }

  Future<CachedTmdbDetailValue<TmdbTvDetailDto>> getCachedTvDetailFull({
    required int showId,
    required String language,
  }) {
    return _get(
      _tvDetailFullKey(showId, language),
      tvDetailFullPolicy,
      TmdbTvDetailDto.fromCache,
    );
  }

  Future<void> putTvDetailFull(
    TmdbTvDetailDto dto, {
    required String language,
  }) {
    return _cache.put(
      key: _tvDetailFullKey(dto.id, language),
      type: 'tmdb_tv_detail_full',
      payload: dto.toCache(),
    );
  }

  Future<CachedTmdbDetailValue<TmdbTvSeasonDetailDto>> getCachedTvSeasonDetail({
    required int showId,
    required int seasonNumber,
    required String language,
  }) async {
    final entry = await _cache.getEntry(
      _tvSeasonDetailKey(showId, seasonNumber, language),
    );
    if (entry == null) {
      return const CachedTmdbDetailValue<TmdbTvSeasonDetailDto>(
        status: CachedTmdbDetailStatus.miss,
      );
    }
    final dto = TmdbTvSeasonDetailDto.fromCache(entry.payload);
    final policy = _seasonPolicyFor(dto);
    return CachedTmdbDetailValue<TmdbTvSeasonDetailDto>(
      status: policy.isExpired(entry.updatedAt)
          ? CachedTmdbDetailStatus.stale
          : CachedTmdbDetailStatus.fresh,
      value: dto,
      updatedAt: entry.updatedAt,
    );
  }

  Future<void> putTvSeasonDetail(
    TmdbTvSeasonDetailDto dto, {
    required int showId,
    required int seasonNumber,
    required String language,
  }) {
    return _cache.put(
      key: _tvSeasonDetailKey(showId, seasonNumber, language),
      type: 'tmdb_tv_season_detail',
      payload: dto.toCache(),
    );
  }

  Future<void> clearMovie(int movieId, {required String language}) async {
    await _cache.remove(_movieDetailLiteKey(movieId, language));
    await _cache.remove(_movieDetailFullKey(movieId, language));
    await _cache.remove(_movieRecommendationsKey(movieId, language));
  }

  Future<void> clearTvShow(int showId, {required String language}) async {
    await _cache.remove(_tvDetailLiteKey(showId, language));
    await _cache.remove(_tvDetailFullKey(showId, language));
  }

  Future<void> clearTvSeason(
    int showId,
    int seasonNumber, {
    required String language,
  }) {
    return _cache.remove(_tvSeasonDetailKey(showId, seasonNumber, language));
  }

  Future<CachedTmdbDetailValue<T>> _get<T>(
    String key,
    CachePolicy policy,
    T Function(Map<String, dynamic> payload) parser,
  ) async {
    final entry = await _cache.getEntry(key);
    if (entry == null) {
      return CachedTmdbDetailValue<T>(status: CachedTmdbDetailStatus.miss);
    }
    final value = parser(entry.payload);
    final isExpired = policy.isExpired(entry.updatedAt);
    return CachedTmdbDetailValue<T>(
      status: isExpired
          ? CachedTmdbDetailStatus.stale
          : CachedTmdbDetailStatus.fresh,
      value: value,
      updatedAt: entry.updatedAt,
    );
  }

  CachePolicy _seasonPolicyFor(TmdbTvSeasonDetailDto dto) {
    DateTime? latestAirDate;
    for (final episode in dto.episodes) {
      final raw = episode.airDate;
      if (raw == null || raw.isEmpty) continue;
      final parsed = DateTime.tryParse(raw);
      if (parsed == null) continue;
      if (latestAirDate == null || parsed.isAfter(latestAirDate)) {
        latestAirDate = parsed;
      }
    }
    if (latestAirDate == null) {
      return tvSeasonActivePolicy;
    }
    final now = DateTime.now();
    final recentlyAiring =
        latestAirDate.isAfter(now.subtract(const Duration(days: 180))) ||
        latestAirDate.isAfter(now);
    return recentlyAiring ? tvSeasonActivePolicy : tvSeasonArchivePolicy;
  }

  String _movieDetailLiteKey(int movieId, String language) =>
      'tmdb_movie_detail_lite_${movieId}_$language';

  String _movieDetailFullKey(int movieId, String language) =>
      'tmdb_movie_detail_full_${movieId}_$language';

  String _movieRecommendationsKey(int movieId, String language) =>
      'tmdb_movie_recommendations_${movieId}_$language';

  String _tvDetailLiteKey(int showId, String language) =>
      'tmdb_tv_detail_lite_${showId}_$language';

  String _tvDetailFullKey(int showId, String language) =>
      'tmdb_tv_detail_full_${showId}_$language';

  String _tvSeasonDetailKey(int showId, int seasonNumber, String language) =>
      'tmdb_tv_season_detail_${showId}_${seasonNumber}_$language';
}
