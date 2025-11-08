// lib/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart
import '../../../../shared/data/services/tmdb_client.dart';
import '../dtos/tmdb_tv_detail_dto.dart';
import '../dtos/tmdb_tv_season_detail_dto.dart';

/// TMDB TV remote datasource
/// - "Lite" = sans append_to_response (léger, pour cartes/listes)
/// - "Full" = avec append (images/credits/recommendations) pour pages détail
class TmdbTvRemoteDataSource {
  TmdbTvRemoteDataSource(this._client);

  final TmdbClient _client;

  /// DÉFAUT allégé (préférer pour l'enrichissement des cartes)
  /// Note: alias de fetchShowLite pour compat ascendante.
  Future<TmdbTvDetailDto> fetchShow(int id) => fetchShowLite(id);

  /// Détail LÉGER (sans append)
  Future<TmdbTvDetailDto> fetchShowLite(int id) {
    return _client.get(
      path: 'tv/$id',
      mapper: (json) => TmdbTvDetailDto.fromJson(json),
    );
  }

  /// Détail COMPLET (append images/credits/recommendations)
  Future<TmdbTvDetailDto> fetchShowFull(int id) {
    return _client.get(
      path: 'tv/$id',
      query: const {'append_to_response': 'images,credits,recommendations'},
      mapper: (json) => TmdbTvDetailDto.fromJson(json),
    );
  }

  Future<TmdbTvSeasonDetailDto> fetchSeason(int showId, int seasonNumber) {
    return _client.get(
      path: 'tv/$showId/season/$seasonNumber',
      mapper: (json) => TmdbTvSeasonDetailDto.fromJson(json),
    );
  }

  Future<List<TmdbTvSummaryDto>> searchShows(String query) {
    return _client.get(
      path: 'search/tv',
      query: {'query': query},
      mapper: (json) => ((json['results'] as List<dynamic>? ?? const [])
          .map((item) => TmdbTvSummaryDto.fromJson(item as Map<String, dynamic>))
          .toList()),
    );
  }

  Future<List<TmdbTvSummaryDto>> fetchPopular() {
    return _client.get(
      path: 'tv/popular',
      mapper: (json) => ((json['results'] as List<dynamic>? ?? const [])
          .map((item) => TmdbTvSummaryDto.fromJson(item as Map<String, dynamic>))
          .toList()),
    );
  }
}
