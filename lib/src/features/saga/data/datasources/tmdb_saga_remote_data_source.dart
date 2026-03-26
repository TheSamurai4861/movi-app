import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/features/saga/data/dtos/tmdb_saga_detail_dto.dart';

class TmdbSagaRemoteDataSource {
  TmdbSagaRemoteDataSource(this._client, this._locale);

  final TmdbClient _client;
  final LocalePreferences _locale;

  Future<TmdbSagaDetailDto> fetchSaga(int id, {String? language}) async {
    final json = await _client.getJson(
      'collection/$id',
      language: language ?? _locale.languageCode,
    );
    return TmdbSagaDetailDto.fromJson(json);
  }

  Future<int?> fetchMovieRuntime(int id) async {
    final json = await _client.getJson('movie/$id');
    return json['runtime'] as int?;
  }

  Future<List<TmdbSagaDetailDto>> searchSagas(String query) async {
    final json = await _client.getJson(
      'search/collection',
      query: {'query': query},
      language: _locale.languageCode,
    );
    final results = json['results'] as List<dynamic>? ?? const [];
    return results
        .map((item) => TmdbSagaDetailDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
