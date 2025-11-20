import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart';

class MovieLocalDataSource {
  MovieLocalDataSource(this._cacheRepository);

  final ContentCacheRepository _cacheRepository;
  static const _movieDetailType = 'movie_detail';
  static const _recommendationsType = 'movie_recommendations';
  static const CachePolicy _detailPolicy = CachePolicy(
    ttl: Duration(hours: 24),
  );
  static const CachePolicy _recommendationPolicy = CachePolicy(
    ttl: Duration(hours: 6),
  );
  static const CachePolicy _defaultPolicy = CachePolicy(
    ttl: Duration(hours: 24),
  );

  Future<void> saveMovieDetail({required TmdbMovieDetailDto dto}) {
    return _cacheRepository.put(
      key: 'movie_detail_${dto.id}',
      type: _movieDetailType,
      payload: dto.toCache(),
    );
  }

  Future<TmdbMovieDetailDto?> getMovieDetail(int movieId) async {
    final cached = await _cacheRepository.getWithPolicy(
      'movie_detail_$movieId',
      _detailPolicy,
    );
    if (cached == null) return null;
    return TmdbMovieDetailDto.fromCache(cached);
  }

  Future<void> saveMovieDetailLang({
    required TmdbMovieDetailDto dto,
    required String lang,
  }) {
    return _cacheRepository.put(
      key: 'movie:$lang:${dto.id}:detail',
      type: _movieDetailType,
      payload: dto.toCache(),
    );
  }

  Future<TmdbMovieDetailDto?> getMovieDetailLang(
    int movieId, {
    required String lang,
    CachePolicy? policy,
  }) async {
    final cached = await _cacheRepository.getWithPolicy(
      'movie:$lang:$movieId:detail',
      policy ?? _defaultPolicy,
    );
    if (cached == null) return null;
    return TmdbMovieDetailDto.fromCache(cached);
  }

  Future<void> saveRecommendations({
    required int movieId,
    required List<TmdbMovieSummaryDto> summaries,
  }) {
    return _cacheRepository.put(
      key: 'movie_reco_$movieId',
      type: _recommendationsType,
      payload: {'items': summaries.map((summary) => summary.toJson()).toList()},
    );
  }

  Future<List<TmdbMovieSummaryDto>?> getRecommendations(int movieId) async {
    final cached = await _cacheRepository.getWithPolicy(
      'movie_reco_$movieId',
      _recommendationPolicy,
    );
    if (cached == null) return null;
    final items = (cached['items'] as List<dynamic>? ?? const [])
        .map(
          (item) => TmdbMovieSummaryDto.fromJson(item as Map<String, dynamic>),
        )
        .toList();
    return items;
  }

  Future<void> saveRecommendationsLang({
    required int movieId,
    required String lang,
    required List<TmdbMovieSummaryDto> summaries,
  }) {
    return _cacheRepository.put(
      key: 'movie:$lang:$movieId:reco',
      type: _recommendationsType,
      payload: {'items': summaries.map((summary) => summary.toJson()).toList()},
    );
  }

  Future<List<TmdbMovieSummaryDto>?> getRecommendationsLang(
    int movieId, {
    required String lang,
    CachePolicy? policy,
  }) async {
    final cached = await _cacheRepository.getWithPolicy(
      'movie:$lang:$movieId:reco',
      policy ?? _defaultPolicy,
    );
    if (cached == null) return null;
    final items = (cached['items'] as List<dynamic>? ?? const [])
        .map(
          (item) => TmdbMovieSummaryDto.fromJson(item as Map<String, dynamic>),
        )
        .toList();
    return items;
  }

  /// Supprime le cache des métadonnées d'un film.
  Future<void> clearMovieDetail(int movieId) async {
    await _cacheRepository.remove('movie_detail_$movieId');
  }

  /// Supprime le cache des recommandations d'un film.
  Future<void> clearRecommendations(int movieId) async {
    await _cacheRepository.remove('movie_reco_$movieId');
  }

  Future<void> clearMovieDetailLang(int movieId, String lang) async {
    await _cacheRepository.remove('movie:$lang:$movieId:detail');
  }

  Future<void> clearRecommendationsLang(int movieId, String lang) async {
    await _cacheRepository.remove('movie:$lang:$movieId:reco');
  }
}
