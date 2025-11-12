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
}
