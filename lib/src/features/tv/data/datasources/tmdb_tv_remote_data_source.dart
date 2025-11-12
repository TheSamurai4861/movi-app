// lib/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart
import 'package:dio/dio.dart';

import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_detail_dto.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_season_detail_dto.dart';

/// Remote data source pour les séries TV TMDB.
/// - I/O réseau délégué à [TmdbClient] (qui force la clé de concurrence "tmdb").
/// - Parsing strict en DTOs, sans manipuler directement `Response`.
/// - Stratégie "lite-first" : payload minimal en liste, payload complet à l’ouverture de la fiche.
class TmdbTvRemoteDataSource {
  TmdbTvRemoteDataSource(this._client);

  final TmdbClient _client;

  /// Raccourci historique — conserve la compat API, mais opte pour la version lite.
  Future<TmdbTvDetailDto> fetchShow(
    int id, {
    String? language,
    CancelToken? cancelToken,
  }) => fetchShowLite(id, language: language, cancelToken: cancelToken);

  /// Détail **léger** d’une série (sans `append_to_response`) pour l’enrichissement en liste.
  Future<TmdbTvDetailDto> fetchShowLite(
    int id, {
    String? language,
    CancelToken? cancelToken,
    int retries = 1,
  }) async {
    final json = await _client.getJson(
      'tv/$id',
      language: language,
      cancelToken: cancelToken,
      retries: retries,
      // cacheTtl: Duration(seconds: 45), // optionnel : TTL custom (sinon défaut executor)
    );
    return TmdbTvDetailDto.fromJson(json);
  }

  /// Détail **complet** d’une série, pour la page fiche.
  /// Ajoute images, crédits, recommandations et content_ratings (utile pour les badges).
  Future<TmdbTvDetailDto> fetchShowFull(
    int id, {
    String? language,
    CancelToken? cancelToken,
    int retries = 1,
  }) async {
    final json = await _client.getJson(
      'tv/$id',
      language: language,
      query: const {
        'append_to_response':
            'images,credits,recommendations,content_ratings,external_ids',
        'include_image_language': 'fr,en,null',
      },
      cancelToken: cancelToken,
      retries: retries,
    );
    return TmdbTvDetailDto.fromJson(json);
  }

  /// Détail d’une **saison** (payload modéré).
  Future<TmdbTvSeasonDetailDto> fetchSeason(
    int showId,
    int seasonNumber, {
    String? language,
    CancelToken? cancelToken,
    int retries = 1,
  }) async {
    final json = await _client.getJson(
      'tv/$showId/season/$seasonNumber',
      language: language,
      cancelToken: cancelToken,
      retries: retries,
    );
    return TmdbTvSeasonDetailDto.fromJson(json);
  }

  /// Recherche de séries — renvoie une liste de résumés.
  Future<List<TmdbTvSummaryDto>> searchShows(
    String query, {
    String? language,
    int page = 1,
    CancelToken? cancelToken,
    int retries = 1,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const <TmdbTvSummaryDto>[];

    final safePage = page < 1 ? 1 : page;
    final json = await _client.getJson(
      'search/tv',
      language: language,
      query: {'query': q, 'page': safePage},
      cancelToken: cancelToken,
      retries: retries,
    );
    final results = (json['results'] as List<dynamic>? ?? const []);
    return results
        .whereType<Map<String, dynamic>>()
        .map(TmdbTvSummaryDto.fromJson)
        .toList(growable: false);
  }

  /// Liste des séries populaires (résumés).
  Future<List<TmdbTvSummaryDto>> fetchPopular({
    String? language,
    int page = 1,
    CancelToken? cancelToken,
    int retries = 1,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final json = await _client.getJson(
      'tv/popular',
      language: language,
      query: {'page': safePage},
      cancelToken: cancelToken,
      retries: retries,
    );
    final results = (json['results'] as List<dynamic>? ?? const []);
    return results
        .whereType<Map<String, dynamic>>()
        .map(TmdbTvSummaryDto.fromJson)
        .toList(growable: false);
  }

  /// (Optionnel) Autres endpoints utiles si besoin de diversité :
  /// - tv/top_rated
  /// - tv/airing_today
  /// - tv/on_the_air
  Future<List<TmdbTvSummaryDto>> fetchTopRated({
    String? language,
    int page = 1,
    CancelToken? cancelToken,
    int retries = 1,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final json = await _client.getJson(
      'tv/top_rated',
      language: language,
      query: {'page': safePage},
      cancelToken: cancelToken,
      retries: retries,
    );
    final results = (json['results'] as List<dynamic>? ?? const []);
    return results
        .whereType<Map<String, dynamic>>()
        .map(TmdbTvSummaryDto.fromJson)
        .toList(growable: false);
  }
}
