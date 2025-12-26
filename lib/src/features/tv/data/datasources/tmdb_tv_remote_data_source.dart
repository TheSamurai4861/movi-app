// lib/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart
import 'package:dio/dio.dart';

import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_detail_dto.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_season_detail_dto.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/di/di.dart';

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
    final String name =
        (json['name']?.toString() ?? json['original_name']?.toString() ?? '')
            .trim();
    final String overview = (json['overview']?.toString() ?? '').trim();
    if (name.isEmpty || overview.isEmpty) {
      final en = await _client.getJson(
        'tv/$id',
        language: 'en-US',
        cancelToken: cancelToken,
        retries: retries,
      );
      if (name.isEmpty) {
        json['name'] = en['name'] ?? en['original_name'];
        json['original_name'] = en['original_name'] ?? en['name'];
      }
      if (overview.isEmpty) {
        json['overview'] = en['overview'];
      }
    }
    return TmdbTvDetailDto.fromJson(json);
  }

  /// Détail léger + images (sans credits/recommendations/content_ratings).
  Future<TmdbTvDetailDto> fetchShowWithImages(
    int id, {
    String? language,
    CancelToken? cancelToken,
    int retries = 1,
  }) async {
    String imgLangs(String? code) {
      final lang = (code ?? '').split('-').first.toLowerCase();
      if (lang.isEmpty || lang == 'en') return 'null,en';
      return '$lang,en,null';
    }

    final json = await _client.getJson(
      'tv/$id',
      language: language,
      cancelToken: cancelToken,
      retries: retries,
    );

    final jsonImages = await _client.getJson(
      'tv/$id/images',
      query: {'include_image_language': imgLangs(language)},
      cancelToken: cancelToken,
      retries: retries,
    );

    final String name =
        (json['name']?.toString() ?? json['original_name']?.toString() ?? '')
            .trim();
    final String overview = (json['overview']?.toString() ?? '').trim();
    if (name.isEmpty || overview.isEmpty) {
      final en = await _client.getJson(
        'tv/$id',
        language: 'en-US',
        cancelToken: cancelToken,
        retries: retries,
      );
      if (name.isEmpty) {
        json['name'] = en['name'] ?? en['original_name'];
        json['original_name'] = en['original_name'] ?? en['name'];
      }
      if (overview.isEmpty) {
        json['overview'] = en['overview'];
      }
    }

    json['images'] = jsonImages;
    return TmdbTvDetailDto.fromJson(json);
  }

  /// Détail **complet** d'une série, pour la page fiche.
  /// Ajoute images, crédits, recommandations et content_ratings (utile pour les badges).
  Future<TmdbTvDetailDto> fetchShowFull(
    int id, {
    String? language,
    CancelToken? cancelToken,
    int retries = 1,
  }) async {
    final logger = sl<AppLogger>();
    logger.debug(
      '📺 [REMOTE] fetchShowFull() démarré pour id=$id, language=$language',
      category: 'tv_remote',
    );

    String imgLangs(String? code) {
      final lang = (code ?? '').split('-').first.toLowerCase();
      if (lang.isEmpty || lang == 'en') return 'null,en';
      return '$lang,en,null';
    }

    logger.debug(
      '📺 [REMOTE] Appel _client.getJson() pour tv/$id avec append_to_response...',
      category: 'tv_remote',
    );
    final getJsonStartTime = DateTime.now();
    final json = await _client.getJson(
      'tv/$id',
      language: language,
      query: {
        'append_to_response':
            'images,credits,recommendations,content_ratings,external_ids',
        'include_image_language': imgLangs(language),
      },
      cancelToken: cancelToken,
      retries: retries,
    );
    final getJsonDuration = DateTime.now().difference(getJsonStartTime);
    logger.debug(
      '📺 [REMOTE] _client.getJson() réussi pour tv/$id en ${getJsonDuration.inMilliseconds}ms',
      category: 'tv_remote',
    );

    final String name =
        (json['name']?.toString() ?? json['original_name']?.toString() ?? '')
            .trim();
    final String overview = (json['overview']?.toString() ?? '').trim();
    logger.debug(
      '📺 [REMOTE] Parsing JSON pour tv/$id: name=${name.isNotEmpty ? "✓" : "✗"}, overview=${overview.isNotEmpty ? "✓" : "✗"}',
      category: 'tv_remote',
    );

    if (name.isEmpty || overview.isEmpty) {
      logger.debug(
        '📺 [REMOTE] Données manquantes pour tv/$id, fallback en-US...',
        category: 'tv_remote',
      );
      final enStartTime = DateTime.now();
      final en = await _client.getJson(
        'tv/$id',
        language: 'en-US',
        query: {
          'append_to_response':
              'images,credits,recommendations,content_ratings,external_ids',
          'include_image_language': imgLangs('en-US'),
        },
        cancelToken: cancelToken,
        retries: retries,
      );
      final enDuration = DateTime.now().difference(enStartTime);
      logger.debug(
        '📺 [REMOTE] Fallback en-US réussi pour tv/$id en ${enDuration.inMilliseconds}ms',
        category: 'tv_remote',
      );
      if (name.isEmpty) {
        json['name'] = en['name'] ?? en['original_name'];
        json['original_name'] = en['original_name'] ?? en['name'];
      }
      if (overview.isEmpty) {
        json['overview'] = en['overview'];
      }
    }

    logger.debug(
      '📺 [REMOTE] Création TmdbTvDetailDto pour tv/$id...',
      category: 'tv_remote',
    );
    final dto = TmdbTvDetailDto.fromJson(json);
    logger.debug(
      '📺 [REMOTE] fetchShowFull() terminé pour id=$id',
      category: 'tv_remote',
    );
    return dto;
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

  /// Trending séries (`window`: 'day' ou 'week').
  Future<List<Map<String, dynamic>>> fetchTrendingShows({
    String window = 'week',
    int page = 1,
    String? language,
    CancelToken? cancelToken,
  }) async {
    final normalizedWindow = (window == 'day') ? 'day' : 'week';
    final json = await _client.getJson(
      'trending/tv/$normalizedWindow',
      query: {'page': page.clamp(1, 1000)},
      language: language,
      cancelToken: cancelToken,
    );
    final results = json['results'];
    if (results is! List) return const <Map<String, dynamic>>[];
    return results.whereType<Map<String, dynamic>>().toList(growable: false);
  }
}
