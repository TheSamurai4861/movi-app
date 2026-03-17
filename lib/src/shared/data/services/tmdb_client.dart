// ignore_for_file: public_member_api_docs

import 'package:dio/dio.dart';
import 'package:movi/src/core/config/config.dart';
import 'package:movi/src/core/network/network.dart';
import 'package:movi/src/shared/domain/services/tmdb_http_client.dart';

/// Client HTTP strict pour TMDB (v3/v4) basé sur [NetworkExecutor].
///
/// Principes :
/// - Aucune clé en dur : tout provient de [NetworkEndpoints].
/// - Déduplication et mini-cache via `dedupKey`/`cacheTtl` de l'exécuteur.
/// - Pas de cast Map→Response : on mappe la réponse **après** l'appel réseau.
/// - URI canoniques et stables : query triée pour une clé de dédup déterministe.
class TmdbClient implements TmdbHttpClient {
  TmdbClient({
    required NetworkExecutor executor,
    required NetworkEndpoints endpoints,
  }) : _executor = executor,
       _endpoints = endpoints;

  final NetworkExecutor _executor;
  final NetworkEndpoints _endpoints;

  /// Récupère un JSON racine **Map** depuis TMDB.
  ///
  /// Exemple de `path`: `movie/550`, `tv/1399`, `search/movie`.
  ///
  /// - `query` : paramètres additionnels, convertis en String.
  /// - `language` : ex. `fr-FR` ou `en-US` (non ajouté si vide).
  /// - `cancelToken` : annulation propre en cas de navigation/scroll.
  /// - `retries` : tentatives supplémentaires (backoff géré par l’exécuteur).
  /// - `cacheTtl` : TTL du mini-cache mémoire de l’exécuteur (si null → défaut).
  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
    String? language,
    CancelToken? cancelToken,
    int retries = 1,
    Duration? cacheTtl,
  }) async {
    // logger.debug(
    //   '🌐 [TMDB] getJson() démarré pour path=$path, language=$language, cancelToken=${cancelToken != null ? "provided" : "null"}',
    //   category: 'tmdb_client',
    // );

    final uri = _buildUri(path: path, query: query, language: language);
    // Pour les requêtes avec cancelToken, utiliser une clé unique pour éviter les blocages
    // de déduplication si une requête précédente est bloquée
    final baseDedupKey = _buildDedupKey('GET', uri);
    final dedupKey = cancelToken != null
        ? '${baseDedupKey}_${cancelToken.hashCode}_${DateTime.now().millisecondsSinceEpoch}'
        : baseDedupKey;
    // logger.debug(
    //   '🌐 [TMDB] URI construit: $uri, dedupKey=$dedupKey (base=$baseDedupKey, avecCancelToken=${cancelToken != null})',
    //   category: 'tmdb_client',
    // );

    // logger.debug(
    //   '🌐 [TMDB] Appel _executor.run() pour path=$path avec cancelToken=${cancelToken != null ? "provided (cancelled: ${cancelToken.isCancelled})" : "null"}...',
    //   category: 'tmdb_client',
    // );
    try {
      // Vérifier si le token est déjà annulé avant d'appeler executor
      if (cancelToken != null && cancelToken.isCancelled) {
        // logger.log(
        //   LogLevel.warn,
        //   '🌐 [TMDB] CancelToken déjà annulé pour path=$path, abandon de la requête',
        //   category: 'tmdb_client',
        // );
        throw DioException(
          requestOptions: RequestOptions(path: uri.toString()),
          type: DioExceptionType.cancel,
          error: 'Request cancelled before execution',
        );
      }

      final result = await _executor.run<dynamic, Map<String, dynamic>>(
        concurrencyKey: 'tmdb',
        dedupKey: dedupKey,
        cacheTtl: cacheTtl,
        retries: retries,
        timeout: const Duration(seconds: 25),
        cancelToken: cancelToken,
        request: (Dio client, CancelToken? token) {
          // Vérifier à nouveau si le token est annulé juste avant l'exécution
          if (token != null && token.isCancelled) {
            // logger.log(
            //   LogLevel.warn,
            //   '🌐 [TMDB] CancelToken annulé juste avant exécution pour path=$path',
            //   category: 'tmdb_client',
            // );
            throw DioException(
              requestOptions: RequestOptions(path: uri.toString()),
              type: DioExceptionType.cancel,
              error: 'Request cancelled before HTTP execution',
            );
          }
          // logger.debug(
          //   '🌐 [TMDB] Exécution requête HTTP pour path=$path, uri=$uri',
          //   category: 'tmdb_client',
          // );
          return client.getUri<dynamic>(
            uri,
            options: Options(
              responseType: ResponseType.json,
              headers: _buildHeaders(),
            ),
            cancelToken: token,
          );
        },
        mapper: (response) {
          // logger.debug(
          //   '🌐 [TMDB] Réponse reçue pour path=$path, statusCode=${response.statusCode}',
          //   category: 'tmdb_client',
          // );
          final data = response.data;
          if (data is Map<String, dynamic>) return data;
          throw TmdbClientError(
            'Unexpected TMDB payload type: ${data.runtimeType}',
            uri: uri,
            statusCode: response.statusCode,
          );
        },
      );
      // logger.debug(
      //   '🌐 [TMDB] getJson() réussi pour path=$path',
      //   category: 'tmdb_client',
      // );
      return result;
    } catch (e) {
      // logger.log(
      //   LogLevel.warn,
      //   '🌐 [TMDB] Erreur dans getJson() pour path=$path: $e',
      //   category: 'tmdb_client',
      //   error: e,
      // );
      rethrow;
    }
  }

  /// Récupère un JSON racine **List** depuis TMDB (certaines routes renvoient une liste).
  ///
  /// Retourne toujours une liste (vide si le payload est vide/inattendu).
  @override
  Future<List<dynamic>> getJsonList(
    String path, {
    Map<String, Object?>? query,
    String? language,
    CancelToken? cancelToken,
    int retries = 1,
    Duration? cacheTtl,
  }) async {
    final uri = _buildUri(path: path, query: query, language: language);
    final dedupKey = _buildDedupKey('GET', uri);

    return _executor.run<dynamic, List<dynamic>>(
      concurrencyKey: 'tmdb',
      dedupKey: dedupKey,
      cacheTtl: cacheTtl,
      retries: retries,
      timeout: const Duration(seconds: 25),
      cancelToken: cancelToken,
      request: (Dio client, CancelToken? token) => client.getUri<dynamic>(
        uri,
        options: Options(
          responseType: ResponseType.json,
          headers: _buildHeaders(),
        ),
        cancelToken: token,
      ),
      mapper: (response) {
        final data = response.data;
        if (data is List<dynamic>) return data;
        if (data is Map<String, dynamic>) {
          final results = data['results'];
          if (results is List<dynamic>) return results;
        }
        return const <dynamic>[];
      },
    );
  }

  // ---------------------------------------------------------------------------
  // URI / Headers
  // ---------------------------------------------------------------------------

  /// Construit un URI TMDB valide en injectant `language` et, si v3, `api_key`.
  Uri _buildUri({
    required String path,
    Map<String, Object?>? query,
    String? language,
  }) {
    final host = _resolveHost();
    final version = _resolveApiVersion();
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;

    // Query canonique triée pour une dédup stable.
    final qp = _canonicalizeQuery(query);

    final lang = _normalizeLanguage(language);
    if (lang != null && lang.isNotEmpty) {
      qp['language'] = lang;
    }

    // Clé v3 en query (sinon Bearer v4 en header).
    final apiKey = _endpoints.tmdbApiKey;
    if (apiKey != null && apiKey.isNotEmpty && _isV3Key(apiKey)) {
      qp.putIfAbsent('api_key', () => apiKey);
    }

    return Uri.https(host, '/$version/$normalizedPath', qp.isEmpty ? null : qp);
  }

  String? _normalizeLanguage(String? language) {
    if (language == null) return null;
    final trimmed = language.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase().replaceAll('_', '-');
    if (lower == 'fr-mm') return 'fr-FR';
    return trimmed;
  }

  Map<String, String> _canonicalizeQuery(Map<String, Object?>? query) {
    if (query == null || query.isEmpty) return <String, String>{};
    final keys = query.keys.where((k) => query[k] != null).toList()..sort();
    final out = <String, String>{};
    for (final k in keys) {
      final v = query[k];
      if (v == null) continue;
      out[k] = v.toString();
    }
    return out;
  }

  String _resolveHost() {
    final fromCfg = _endpoints.tmdbBaseHost?.trim();
    if (fromCfg != null && fromCfg.isNotEmpty) return fromCfg;
    try {
      return _endpoints.resolvedTmdbBaseHost;
    } catch (_) {
      return 'api.themoviedb.org';
    }
  }

  String _resolveApiVersion() {
    final fromCfg = _endpoints.tmdbApiVersion?.trim();
    if (fromCfg != null && fromCfg.isNotEmpty) return fromCfg;
    try {
      return _endpoints.resolvedTmdbApiVersion;
    } catch (_) {
      return '3';
    }
  }

  bool _isV3Key(String key) => !key.startsWith('eyJ') && key.length <= 64;

  Map<String, String> _buildHeaders() {
    final apiKey = _endpoints.tmdbApiKey;
    final headers = <String, String>{'Accept': 'application/json'};
    // Si API v4 : Authorization: Bearer <token>
    if (apiKey != null && apiKey.isNotEmpty && !_isV3Key(apiKey)) {
      headers['Authorization'] = 'Bearer $apiKey';
    }
    return headers;
  }

  /// Clé stable pour la déduplication/caching mémoire de l’exécuteur.
  String _buildDedupKey(String method, Uri uri) {
    final qp = _canonicalizeQuery(uri.queryParameters);
    final canonical = Uri(
      scheme: uri.scheme,
      host: uri.host,
      path: uri.path,
      queryParameters: qp.isEmpty ? null : qp,
    ).toString();
    return '$method|$canonical';
  }
}

/// Erreur spécifique TMDB surfacée aux appelants.
class TmdbClientError implements Exception {
  TmdbClientError(this.message, {this.uri, this.statusCode});

  final String message;
  final Uri? uri;
  final int? statusCode;

  @override
  String toString() {
    final b = StringBuffer('TmdbClientError: $message');
    if (statusCode != null) b.write(' (status=$statusCode)');
    if (uri != null) b.write(' uri=$uri');
    return b.toString();
  }
}
