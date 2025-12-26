import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_detail_dto.dart';
import 'package:movi/src/features/person/data/dtos/tmdb_person_detail_dto.dart';

class TmdbSearchRemoteDataSource {
  TmdbSearchRemoteDataSource(this._client, this._locale);

  final TmdbClient _client;
  final LocalePreferences _locale;

  Future<({List<TmdbMovieSummaryDto> items, int totalPages})> searchMovies(
    String query, {
    int page = 1,
  }) async {
    final json = await _client.getJson(
      'search/movie',
      query: {'query': query, 'page': page},
      language: _locale.languageCode,
    );
    final items = (json['results'] as List<dynamic>? ?? const [])
        .map((e) => TmdbMovieSummaryDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    final totalPages = (json['total_pages'] as int?) ?? 1;
    return (items: items, totalPages: totalPages);
  }

  Future<({List<TmdbTvSummaryDto> items, int totalPages})> searchShows(
    String query, {
    int page = 1,
  }) async {
    final json = await _client.getJson(
      'search/tv',
      query: {'query': query, 'page': page},
      language: _locale.languageCode,
    );
    final items = (json['results'] as List<dynamic>? ?? const [])
        .map((e) => TmdbTvSummaryDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    final totalPages = (json['total_pages'] as int?) ?? 1;
    return (items: items, totalPages: totalPages);
  }

  Future<({List<TmdbPersonDetailDto> items, int totalPages})> searchPeople(
    String query, {
    int page = 1,
  }) async {
    final json = await _client.getJson(
      'search/person',
      query: {'query': query, 'page': page},
      language: _locale.languageCode,
    );
    final items = (json['results'] as List<dynamic>? ?? const [])
        .map(
          (e) => TmdbPersonDetailDto.fromJson(e as Map<String, dynamic>, {
            'cast': const [],
            'crew': const [],
          }),
        )
        .toList(growable: false);
    final totalPages = (json['total_pages'] as int?) ?? 1;
    return (items: items, totalPages: totalPages);
  }
}
