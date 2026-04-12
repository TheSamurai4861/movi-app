import 'package:movi/src/core/storage/repositories/content_cache_repository.dart';
import 'package:movi/src/core/storage/services/cache_policy.dart';
import 'package:movi/src/features/search/data/dtos/tmdb_watch_provider_dto.dart';
import 'package:movi/src/features/search/domain/entities/tmdb_genre.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class TmdbProviderPopularMediaCacheEntry {
  const TmdbProviderPopularMediaCacheEntry({
    required this.posterUrl,
    this.backdropUrl,
    this.isMovie = true,
  });

  final String? posterUrl;
  final String? backdropUrl;
  final bool isMovie;
}

enum CachedDiscoveryStatus { fresh, stale, miss }

class CachedDiscoveryValue<T> {
  const CachedDiscoveryValue({
    required this.status,
    this.value,
    this.updatedAt,
  });

  final CachedDiscoveryStatus status;
  final T? value;
  final DateTime? updatedAt;

  bool get isFresh => status == CachedDiscoveryStatus.fresh && value != null;
  bool get isStale => status == CachedDiscoveryStatus.stale && value != null;
  bool get isMiss => status == CachedDiscoveryStatus.miss || value == null;
}

class TmdbDiscoveryCacheDataSource {
  TmdbDiscoveryCacheDataSource(this._cache);

  final ContentCacheRepository _cache;

  static const CachePolicy trendingPolicy = CachePolicy(
    ttl: Duration(hours: 12),
  );
  static const CachePolicy genresPolicy = CachePolicy(ttl: Duration(days: 7));
  static const CachePolicy watchProvidersPolicy = CachePolicy(
    ttl: Duration(hours: 24),
  );
  static const CachePolicy providerPopularMediaPolicy = CachePolicy(
    ttl: Duration(hours: 24),
  );

  Future<CachedDiscoveryValue<List<Map<String, dynamic>>>>
  getCachedTrendingMovies({
    required String language,
    required String sourceFingerprint,
    int page = 1,
  }) {
    return _get(
      _trendingMoviesKey(language, sourceFingerprint, page),
      trendingPolicy,
      _parseMapList,
    );
  }

  Future<void> putTrendingMovies(
    List<Map<String, dynamic>> items, {
    required String language,
    required String sourceFingerprint,
    int page = 1,
  }) {
    return _cache.put(
      key: _trendingMoviesKey(language, sourceFingerprint, page),
      type: 'tmdb_discovery_trending',
      payload: <String, dynamic>{'items': items},
    );
  }

  Future<CachedDiscoveryValue<List<Map<String, dynamic>>>>
  getCachedTrendingShows({
    required String language,
    required String sourceFingerprint,
    int page = 1,
  }) {
    return _get(
      _trendingShowsKey(language, sourceFingerprint, page),
      trendingPolicy,
      _parseMapList,
    );
  }

  Future<void> putTrendingShows(
    List<Map<String, dynamic>> items, {
    required String language,
    required String sourceFingerprint,
    int page = 1,
  }) {
    return _cache.put(
      key: _trendingShowsKey(language, sourceFingerprint, page),
      type: 'tmdb_discovery_trending',
      payload: <String, dynamic>{'items': items},
    );
  }

  Future<CachedDiscoveryValue<List<TmdbWatchProviderDto>>>
  getCachedWatchProviders({required String region, required String language}) {
    return _get(_watchProvidersKey(region, language), watchProvidersPolicy, (
      payload,
    ) {
      final list = payload['items'] as List<dynamic>? ?? const <dynamic>[];
      return list
          .whereType<Map<String, dynamic>>()
          .map(TmdbWatchProviderDto.fromJson)
          .toList(growable: false);
    });
  }

  Future<void> putWatchProviders(
    List<TmdbWatchProviderDto> providers, {
    required String region,
    required String language,
  }) {
    return _cache.put(
      key: _watchProvidersKey(region, language),
      type: 'tmdb_watch_providers',
      payload: <String, dynamic>{
        'items': providers.map((dto) => dto.toJson()).toList(growable: false),
      },
    );
  }

  Future<CachedDiscoveryValue<TmdbGenres>> getCachedGenres({
    required String language,
  }) {
    return _get(_genresKey(language), genresPolicy, (payload) {
      List<TmdbGenre> parseList(List<dynamic>? raw, ContentType type) {
        return (raw ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(
              (item) => TmdbGenre(
                id: item['id'] as int,
                name: item['name'] as String,
                type: type,
              ),
            )
            .toList(growable: false);
      }

      return TmdbGenres(
        movie: parseList(payload['movie'] as List<dynamic>?, ContentType.movie),
        series: parseList(
          payload['series'] as List<dynamic>?,
          ContentType.series,
        ),
      );
    });
  }

  Future<void> putGenres(TmdbGenres genres, {required String language}) {
    Map<String, dynamic> encodeGenre(TmdbGenre genre) => <String, dynamic>{
      'id': genre.id,
      'name': genre.name,
    };

    return _cache.put(
      key: _genresKey(language),
      type: 'tmdb_genres',
      payload: <String, dynamic>{
        'movie': genres.movie.map(encodeGenre).toList(growable: false),
        'series': genres.series.map(encodeGenre).toList(growable: false),
      },
    );
  }

  Future<CachedDiscoveryValue<TmdbProviderPopularMediaCacheEntry>>
  getCachedProviderPopularMedia({
    required int providerId,
    required String region,
    required String language,
  }) {
    return _get(
      _providerPopularMediaKey(providerId, region, language),
      providerPopularMediaPolicy,
      (payload) => TmdbProviderPopularMediaCacheEntry(
        posterUrl: payload['posterUrl'] as String?,
        backdropUrl: payload['backdropUrl'] as String?,
        isMovie: payload['isMovie'] as bool? ?? true,
      ),
    );
  }

  Future<void> putProviderPopularMedia(
    TmdbProviderPopularMediaCacheEntry media, {
    required int providerId,
    required String region,
    required String language,
  }) {
    return _cache.put(
      key: _providerPopularMediaKey(providerId, region, language),
      type: 'tmdb_provider_popular_media',
      payload: <String, dynamic>{
        'posterUrl': media.posterUrl,
        'backdropUrl': media.backdropUrl,
        'isMovie': media.isMovie,
      },
    );
  }

  Future<CachedDiscoveryValue<T>> _get<T>(
    String key,
    CachePolicy policy,
    T Function(Map<String, dynamic> payload) parser,
  ) async {
    final entry = await _cache.getEntry(key);
    if (entry == null) {
      return CachedDiscoveryValue<T>(status: CachedDiscoveryStatus.miss);
    }
    final value = parser(entry.payload);
    final isExpired = policy.isExpired(entry.updatedAt);
    return CachedDiscoveryValue<T>(
      status: isExpired
          ? CachedDiscoveryStatus.stale
          : CachedDiscoveryStatus.fresh,
      value: value,
      updatedAt: entry.updatedAt,
    );
  }

  static List<Map<String, dynamic>> _parseMapList(
    Map<String, dynamic> payload,
  ) {
    return (payload['items'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  String _trendingMoviesKey(
    String language,
    String sourceFingerprint,
    int page,
  ) =>
      'tmdb_home_trending_movies_${language}_$sourceFingerprint'
      '${page > 1 ? '_page_$page' : ''}';

  String _trendingShowsKey(
    String language,
    String sourceFingerprint,
    int page,
  ) =>
      'tmdb_home_trending_tv_${language}_$sourceFingerprint'
      '${page > 1 ? '_page_$page' : ''}';

  String _genresKey(String language) => 'tmdb_genres_$language';

  String _watchProvidersKey(String region, String language) =>
      'tmdb_watch_providers_movie_${region}_$language';

  String _providerPopularMediaKey(
    int providerId,
    String region,
    String language,
  ) => 'tmdb_provider_popular_media_${providerId}_${region}_$language';
}
