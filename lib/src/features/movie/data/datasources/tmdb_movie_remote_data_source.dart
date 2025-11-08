// lib/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart
import '../../../../shared/data/services/tmdb_client.dart';
import '../dtos/tmdb_movie_detail_dto.dart';

/// TMDB Movies remote datasource
/// - "Lite" = sans append_to_response (léger, pour cartes/listes)
/// - "Full" = avec append (images/credits/recommendations) pour les pages détail/Hero
class TmdbMovieRemoteDataSource {
  TmdbMovieRemoteDataSource(this._client);

  final TmdbClient _client;

  /// DÉFAUT allégé (préférer pour l'enrichissement des cartes)
  /// Note: alias de fetchMovieLite pour compat ascendante.
  Future<TmdbMovieDetailDto> fetchMovie(int id) => fetchMovieLite(id);

  /// Détail LÉGER (sans append)
  Future<TmdbMovieDetailDto> fetchMovieLite(int id) {
    return _client.get(
      path: 'movie/$id',
      mapper: (json) => TmdbMovieDetailDto.fromJson(json),
    );
  }

  /// Détail COMPLET (append images/credits/recommendations)
  Future<TmdbMovieDetailDto> fetchMovieFull(int id) {
    return _client.get(
      path: 'movie/$id',
      query: const {'append_to_response': 'images,credits,recommendations'},
      mapper: (json) => TmdbMovieDetailDto.fromJson(json),
    );
  }

  Future<List<TmdbMovieSummaryDto>> searchMovies(String query) {
    return _client.get(
      path: 'search/movie',
      query: {'query': query},
      mapper: (json) => ((json['results'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                TmdbMovieSummaryDto.fromJson(item as Map<String, dynamic>),
          )
          .toList()),
    );
  }

  Future<List<TmdbMovieSummaryDto>> fetchPopular() {
    return _client.get(
      path: 'movie/popular',
      mapper: (json) => ((json['results'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                TmdbMovieSummaryDto.fromJson(item as Map<String, dynamic>),
          )
          .toList()),
    );
  }

  /// Trending movies for the hero section (TMDB), paginable.
  Future<List<TmdbMovieSummaryDto>> fetchTrendingMovies({
    String window = 'week',
    int page = 1,
  }) async {
    final json = await _client.getJson(
      'trending/movie/$window',
      query: {'page': page},
    );
    final results = (json['results'] as List<dynamic>? ?? const []);
    return results
        .map((e) => TmdbMovieSummaryDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
