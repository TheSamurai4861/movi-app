import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/features/person/data/dtos/tmdb_person_detail_dto.dart';

class TmdbPersonRemoteDataSource {
  TmdbPersonRemoteDataSource(this._client);

  final TmdbClient _client;

  Future<TmdbPersonDetailDto> fetchPerson(int id, {String? language}) async {
    final detail = await _client.getJson('person/$id', language: language);
    final credits = await _client.getJson(
      'person/$id/combined_credits',
      language: language,
    );
    return TmdbPersonDetailDto.fromJson(detail, credits);
  }

  Future<List<TmdbPersonDetailDto>> searchPeople(
    String query, {
    String? language,
  }) async {
    final results = await _client.getJson(
      'search/person',
      query: {'query': query},
      language: language,
    );
    final list = (results['results'] as List<dynamic>? ?? const []);
    return list
        .map(
          (item) => TmdbPersonDetailDto.fromJson(item as Map<String, dynamic>, {
            'cast': const [],
            'crew': const [],
          }),
        )
        .toList();
  }
}
