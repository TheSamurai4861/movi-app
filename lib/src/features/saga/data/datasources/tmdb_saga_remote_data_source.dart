import '../../../../shared/data/services/tmdb_client.dart';
import '../dtos/tmdb_saga_detail_dto.dart';

class TmdbSagaRemoteDataSource {
  TmdbSagaRemoteDataSource(this._client);

  final TmdbClient _client;

  Future<TmdbSagaDetailDto> fetchSaga(int id) {
    return _client.get(
      path: 'collection/$id',
      mapper: (json) => TmdbSagaDetailDto.fromJson(json),
    );
  }

  Future<int?> fetchMovieRuntime(int id) async {
    final json = await _client.getJson('movie/$id');
    return json['runtime'] as int?;
  }

  Future<List<TmdbSagaDetailDto>> searchSagas(String query) async {
    final json = await _client.getJson('search/collection', query: {'query': query});
    final results = json['results'] as List<dynamic>? ?? const [];
    return results.map((item) => TmdbSagaDetailDto.fromJson(item as Map<String, dynamic>)).toList();
  }
}
