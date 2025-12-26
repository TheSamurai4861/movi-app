// lib/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart
import 'package:dio/dio.dart';

import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart';

/// Remote data source pour les FILMS TMDB.
/// - Tout l’I/O réseau + gestion d’erreurs est délégué à [TmdbClient].
/// - Cette couche ne manipule **que** des `Map<String, dynamic>` décodés.
/// - Aucune dépendance à `Response`, uniquement mapping en DTOs.
class TmdbMovieRemoteDataSource {
  const TmdbMovieRemoteDataSource(this._client);

  final TmdbClient _client;

  /// Détail léger (sans `append_to_response`).
  Future<TmdbMovieDetailDto> fetchMovieLite(
    int id, {
    String? language,
    CancelToken? cancelToken,
  }) async {
    final json = await _client.getJson(
      'movie/$id',
      language: language,
      cancelToken: cancelToken,
    );
    final String title =
        (json['title']?.toString() ?? json['original_title']?.toString() ?? '')
            .trim();
    final String overview = (json['overview']?.toString() ?? '').trim();
    if (title.isEmpty || overview.isEmpty) {
      final en = await _client.getJson(
        'movie/$id',
        language: 'en-US',
        cancelToken: cancelToken,
      );
      if (title.isEmpty) {
        json['title'] = en['title'] ?? en['original_title'];
        json['original_title'] = en['original_title'] ?? en['title'];
      }
      if (overview.isEmpty) {
        json['overview'] = en['overview'];
      }
    }
    return TmdbMovieDetailDto.fromJson(json);
  }

  /// Détail léger + images (sans credits/recommendations).
  Future<TmdbMovieDetailDto> fetchMovieWithImages(
    int id, {
    String? language,
    CancelToken? cancelToken,
    int retries = 1,
  }) async {
    final json = await _client.getJson(
      'movie/$id',
      language: language,
      cancelToken: cancelToken,
      retries: retries,
    );

    String imgLangs(String? code) {
      final lang = (code ?? '').split('-').first.toLowerCase();
      if (lang.isEmpty || lang == 'en') return 'null,en';
      return '$lang,en,null';
    }

    final jsonImages = await _client.getJson(
      'movie/$id/images',
      query: {'include_image_language': imgLangs(language)},
      cancelToken: cancelToken,
      retries: retries,
    );

    final String title =
        (json['title']?.toString() ?? json['original_title']?.toString() ?? '')
            .trim();
    final String overview = (json['overview']?.toString() ?? '').trim();
    if (title.isEmpty || overview.isEmpty) {
      final en = await _client.getJson(
        'movie/$id',
        language: 'en-US',
        cancelToken: cancelToken,
        retries: retries,
      );
      if (title.isEmpty) {
        json['title'] = en['title'] ?? en['original_title'];
        json['original_title'] = en['original_title'] ?? en['title'];
      }
      if (overview.isEmpty) {
        json['overview'] = en['overview'];
      }
    }

    json['images'] = jsonImages;
    return TmdbMovieDetailDto.fromJson(json);
  }

  /// Alias de compatibilité vers [fetchMovieLite].
  Future<TmdbMovieDetailDto> fetchMovie(
    int id, {
    String? language,
    CancelToken? cancelToken,
  }) {
    return fetchMovieLite(id, language: language, cancelToken: cancelToken);
  }

  /// Détail complet avec `append_to_response` (images/credits/recommendations).
  Future<TmdbMovieDetailDto> fetchMovieFull(
    int id, {
    String? language,
    CancelToken? cancelToken,
  }) async {
    final json = await _client.getJson(
      'movie/$id',
      query: const {'append_to_response': 'credits,recommendations'},
      language: language,
      cancelToken: cancelToken,
    );

    String imgLangs(String? code) {
      final lang = (code ?? '').split('-').first.toLowerCase();
      if (lang.isEmpty || lang == 'en') return 'null,en';
      return '$lang,en,null';
    }

    final jsonImages = await _client.getJson(
      'movie/$id/images',
      query: {'include_image_language': imgLangs(language)},
      cancelToken: cancelToken,
    );

    final String title =
        (json['title']?.toString() ?? json['original_title']?.toString() ?? '')
            .trim();
    final String overview = (json['overview']?.toString() ?? '').trim();
    if (title.isEmpty || overview.isEmpty) {
      final en = await _client.getJson(
        'movie/$id',
        query: const {'append_to_response': 'credits,recommendations'},
        language: 'en-US',
        cancelToken: cancelToken,
      );
      if (title.isEmpty) {
        json['title'] = en['title'] ?? en['original_title'];
        json['original_title'] = en['original_title'] ?? en['title'];
      }
      if (overview.isEmpty) {
        json['overview'] = en['overview'];
      }
    }

    json['images'] = jsonImages;
    return TmdbMovieDetailDto.fromJson(json);
  }

  /// Recherche de films (paginée côté TMDB).
  Future<List<TmdbMovieSummaryDto>> searchMovies(
    String query, {
    int page = 1,
    String? language,
    CancelToken? cancelToken,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const <TmdbMovieSummaryDto>[];
    final json = await _client.getJson(
      'search/movie',
      query: {'query': q, 'page': page.clamp(1, 1000)},
      language: language,
      cancelToken: cancelToken,
    );
    final results = json['results'];
    if (results is! List) return const <TmdbMovieSummaryDto>[];
    return results
        .whereType<Map<String, dynamic>>()
        .map(TmdbMovieSummaryDto.fromJson)
        .toList(growable: false);
  }

  /// Films populaires (paginé).
  Future<List<TmdbMovieSummaryDto>> fetchPopular({
    int page = 1,
    String? language,
    CancelToken? cancelToken,
  }) async {
    final json = await _client.getJson(
      'movie/popular',
      query: {'page': page.clamp(1, 1000)},
      language: language,
      cancelToken: cancelToken,
    );
    final results = json['results'];
    if (results is! List) return const <TmdbMovieSummaryDto>[];
    return results
        .whereType<Map<String, dynamic>>()
        .map(TmdbMovieSummaryDto.fromJson)
        .toList(growable: false);
  }

  /// Trending films (`window`: 'day' ou 'week').
  Future<List<Map<String, dynamic>>> fetchTrendingMovies({
    String window = 'week',
    int page = 1,
    String? language,
    CancelToken? cancelToken,
  }) async {
    final normalizedWindow = (window == 'day') ? 'day' : 'week';
    final json = await _client.getJson(
      'trending/movie/$normalizedWindow',
      query: {'page': page.clamp(1, 1000)},
      language: language,
      cancelToken: cancelToken,
    );
    final results = json['results'];
    if (results is! List) return const <Map<String, dynamic>>[];
    return results.whereType<Map<String, dynamic>>().toList(growable: false);
  }
}
