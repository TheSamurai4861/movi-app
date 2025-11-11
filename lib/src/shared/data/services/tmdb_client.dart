// lib/src/shared/data/services/tmdb_client.dart
import 'package:dio/dio.dart';
import 'package:movi/src/core/config/models/network_endpoints.dart';
import 'package:movi/src/core/network/network_executor.dart';

/// Client HTTP strict pour TMDB.
/// - Concurrency key toujours "tmdb" (partage le même pool).
/// - Déduplication et mini-cache via `dedupKey` passé à `NetworkExecutor`.
/// - Jamais de cast Map→Response : on mappe la réponse en `Map<String, dynamic>`.
/// - Aucune clé en dur : tout provient de `NetworkEndpoints` (v3 en query, v4 en Bearer).
class TmdbClient {
  TmdbClient({
    required NetworkExecutor executor,
    required NetworkEndpoints endpoints,
  })  : _executor = executor,
        _endpoints = endpoints;

  final NetworkExecutor _executor;
  final NetworkEndpoints _endpoints;

  /// Récupère un JSON (racine Map) depuis TMDB pour [path] (ex. `movie/550`).
  ///
  /// - `query` : paramètres additionnels (clés/valeurs sérialisées en String).
  /// - `language` : ajoute `language=xx-YY`.
  /// - `cancelToken` : permet d’annuler proprement en cas de scroll/changement de batch.
  /// - `retries` : nombre de tentatives supplémentaires (backoff géré par l’exécuteur).
  /// - `cacheTtl` : TTL du mini-cache mémoire (si null → valeur par défaut de l’exécuteur).
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
    String? language,
    CancelToken? cancelToken,
    int retries = 1,
    Duration? cacheTtl,
  }) async {
    final uri = _buildUri(path: path, query: query, language: language);
    final dedupKey = _buildDedupKey('GET', uri);

    return _executor.run<dynamic, Map<String, dynamic>>(
      concurrencyKey: 'tmdb',
      dedupKey: dedupKey,
      cacheTtl: cacheTtl,
      retries: retries,
      cancelToken: cancelToken,
      request: (Dio client) => client.getUri<dynamic>(
        uri,
        options: Options(
          responseType: ResponseType.json,
          headers: _buildHeaders(),
        ),
        cancelToken: cancelToken,
      ),
      mapper: (response) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return data;
        }
        throw TmdbClientError(
          'Unexpected TMDB payload type: ${data.runtimeType}',
          uri: uri,
          statusCode: response.statusCode,
        );
      },
    );
  }

  /// Construit un URI TMDB valide en injectant `language` et (si v3) `api_key`.
  Uri _buildUri({
    required String path,
    Map<String, Object?>? query,
    String? language,
  }) {
    final host = _resolveHost();
    final version = _resolveApiVersion();
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;

    // Query canonique triée pour que la clé de dédup soit stable.
    final qp = _canonicalizeQuery(query);

    if (language != null && language.isNotEmpty) {
      qp['language'] = language;
    }

    // Si on utilise une clé v3, on l’ajoute dans la query.
    final apiKey = _endpoints.tmdbApiKey;
    if (apiKey != null && apiKey.isNotEmpty && _isV3Key(apiKey)) {
      qp.putIfAbsent('api_key', () => apiKey);
    }

    return Uri.https(host, '/$version/$normalizedPath', qp.isEmpty ? null : qp);
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

  /// Détermine l’hôte TMDB (config > fallback).
  String _resolveHost() {
    final fromCfg = _endpoints.tmdbBaseHost?.trim();
    if (fromCfg != null && fromCfg.isNotEmpty) return fromCfg;
    try {
      return _endpoints.resolvedTmdbBaseHost;
    } catch (_) {
      return 'api.themoviedb.org';
    }
  }

  /// Détermine la version d’API (config > fallback "3").
  String _resolveApiVersion() {
    final fromCfg = _endpoints.tmdbApiVersion?.trim();
    if (fromCfg != null && fromCfg.isNotEmpty) return fromCfg;
    try {
      return _endpoints.resolvedTmdbApiVersion;
    } catch (_) {
      return '3';
    }
  }

  /// Heuristique : une clé v4 (JWT) commence souvent par "eyJ".
  bool _isV3Key(String key) => !key.startsWith('eyJ') && key.length <= 64;

  /// Construit les headers (Bearer v4 si nécessaire, Accept JSON).
  Map<String, String> _buildHeaders() {
    final apiKey = _endpoints.tmdbApiKey;
    final headers = <String, String>{'Accept': 'application/json'};
    if (apiKey != null && apiKey.isNotEmpty && !_isV3Key(apiKey)) {
      headers['Authorization'] = 'Bearer $apiKey';
    }
    return headers;
  }

  /// Clé stable pour la dé-duplication/caching mémoire de l’exécuteur.
  String _buildDedupKey(String method, Uri uri) {
    // On reconstruit la query triée pour éviter les variations d’ordre.
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

/// Erreur spécifique TMDB, pour surface propre côté appelants.
class TmdbClientError implements Exception {
  TmdbClientError(
    this.message, {
    this.uri,
    this.statusCode,
  });

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
