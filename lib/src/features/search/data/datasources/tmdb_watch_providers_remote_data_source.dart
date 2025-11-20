// lib/src/features/search/data/datasources/tmdb_watch_providers_remote_data_source.dart
import 'package:dio/dio.dart';

import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/features/search/data/dtos/tmdb_watch_provider_dto.dart';
import 'package:movi/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_detail_dto.dart';
import 'package:movi/src/features/search/domain/entities/search_page.dart';

/// Remote data source pour les watch providers TMDB.
class TmdbWatchProvidersRemoteDataSource {
  TmdbWatchProvidersRemoteDataSource(this._client);

  final TmdbClient _client;

  static const Duration _regionsTtl = Duration(hours: 12);
  static const Duration _providersTtl = Duration(hours: 12);
  static const Duration _discoverTtl = Duration(minutes: 30);

  List<dynamic>? _cachedRegions;
  DateTime? _regionsCachedAt;
  final Map<String, ({List<TmdbWatchProviderDto> providers, DateTime cachedAt})>
      _providersCache = <String, ({List<TmdbWatchProviderDto> providers, DateTime cachedAt})>{};

  /// Récupère la liste des watch providers disponibles pour les films.
  /// Utilise l'endpoint watch/providers/movie avec la région de l'utilisateur.
  Future<List<TmdbWatchProviderDto>> fetchWatchProviders({
    String? language,
    String? watchRegion,
    CancelToken? cancelToken,
  }) async {
    // Récupérer et mémoïser les régions disponibles (TTL 12h)
    final bool regionsValid = _regionsCachedAt != null &&
        DateTime.now().difference(_regionsCachedAt!) < _regionsTtl;
    if (!regionsValid) {
      final regionsJson = await _client.getJson(
        'watch/providers/regions',
        language: language,
        cancelToken: cancelToken,
        retries: 2,
        cacheTtl: _regionsTtl,
      );
      _cachedRegions = regionsJson['results'] as List<dynamic>? ?? const [];
      _regionsCachedAt = DateTime.now();
    }

    // Utiliser la région spécifiée ou FR par défaut
    final region = watchRegion ?? 'FR';

    // Vérifier si la région existe dans la liste (depuis cache mémoïsé)
    final regions = _cachedRegions ?? const [];
    final validRegion =
        regions.any((r) => r is Map && r['iso_3166_1'] == region)
        ? region
        : 'FR';

    // Cache providers par région (TTL 12h)
    final cacheEntry = _providersCache[validRegion];
    final bool providersValid = cacheEntry != null &&
        DateTime.now().difference(cacheEntry.cachedAt) < _providersTtl;
    if (providersValid) {
      return cacheEntry.providers;
    }

    final providersJson = await _client.getJson(
      'watch/providers/movie',
      query: {'watch_region': validRegion},
      language: language,
      cancelToken: cancelToken,
      retries: 2,
      cacheTtl: _providersTtl,
    );

    final results = providersJson['results'] as List<dynamic>? ?? [];
    final parsed = results
        .whereType<Map<String, dynamic>>()
        .map((json) => TmdbWatchProviderDto.fromJson(json))
        .where(
          (provider) =>
              provider.logoPath != null &&
              provider.logoPath!.isNotEmpty &&
              provider.displayPriority != null,
        )
        .toList(growable: false);

    _providersCache[validRegion] = (providers: parsed, cachedAt: DateTime.now());
    return parsed;
  }

  Future<SearchPage<TmdbMovieSummaryDto>> getMoviesByProvider(
    int providerId, {
    String region = 'FR',
    int page = 1,
    String? language,
    CancelToken? cancelToken,
  }) async {
    final json = await _client.getJson(
      'discover/movie',
      query: {
        'with_watch_providers': providerId.toString(),
        'watch_region': region,
        'page': page,
      },
      language: language,
      cancelToken: cancelToken,
      retries: 2,
      cacheTtl: _discoverTtl,
    );

    final results = (json['results'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => TmdbMovieSummaryDto.fromJson(e))
        .toList();

    final totalPages = json['total_pages'] as int? ?? 1;

    return SearchPage(items: results, page: page, totalPages: totalPages);
  }

  Future<SearchPage<TmdbTvSummaryDto>> getShowsByProvider(
    int providerId, {
    String region = 'FR',
    int page = 1,
    String? language,
    CancelToken? cancelToken,
  }) async {
    final json = await _client.getJson(
      'discover/tv',
      query: {
        'with_watch_providers': providerId.toString(),
        'watch_region': region,
        'page': page,
      },
      language: language,
      cancelToken: cancelToken,
      retries: 2,
      cacheTtl: _discoverTtl,
    );

    final results = (json['results'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => TmdbTvSummaryDto.fromJson(e))
        .toList();

    final totalPages = json['total_pages'] as int? ?? 1;

    return SearchPage(items: results, page: page, totalPages: totalPages);
  }
}
