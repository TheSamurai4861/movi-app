import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/features/saga/data/dtos/tmdb_saga_detail_dto.dart';

class TmdbSagaRemoteDataSource {
  TmdbSagaRemoteDataSource(this._client);

  final TmdbClient _client;

  Future<TmdbSagaDetailDto> fetchSaga(int id, {String? language}) async {
    final query = language != null ? {'language': language} : null;
    final json = await _client.getJson('collection/$id', query: query);
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
    );
    final results = json['results'] as List<dynamic>? ?? const [];
    return results
        .map((item) => TmdbSagaDetailDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
