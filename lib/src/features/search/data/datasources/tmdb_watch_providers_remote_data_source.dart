// lib/src/features/search/data/datasources/tmdb_watch_providers_remote_data_source.dart
import 'package:dio/dio.dart';

import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/features/search/data/dtos/tmdb_watch_provider_dto.dart';

/// Remote data source pour les watch providers TMDB.
class TmdbWatchProvidersRemoteDataSource {
  const TmdbWatchProvidersRemoteDataSource(this._client);

  final TmdbClient _client;

  /// Récupère la liste des watch providers disponibles pour les films.
  /// Utilise l'endpoint watch/providers/movie avec la région de l'utilisateur.
  Future<List<TmdbWatchProviderDto>> fetchWatchProviders({
    String? language,
    String? watchRegion,
    CancelToken? cancelToken,
  }) async {
    // D'abord, récupérer les régions disponibles
    final regionsJson = await _client.getJson(
      'watch/providers/regions',
      language: language,
      cancelToken: cancelToken,
    );

    // Utiliser la région spécifiée ou FR par défaut
    final region = watchRegion ?? 'FR';

    // Vérifier si la région existe dans la liste
    final regions = regionsJson['results'] as List<dynamic>? ?? [];
    final validRegion =
        regions.any((r) => r is Map && r['iso_3166_1'] == region)
        ? region
        : 'FR';

    // Récupérer les providers pour les films dans cette région
    final providersJson = await _client.getJson(
      'watch/providers/movie',
      query: {'watch_region': validRegion},
      language: language,
      cancelToken: cancelToken,
    );

    final results = providersJson['results'] as List<dynamic>? ?? [];

    return results
        .whereType<Map<String, dynamic>>()
        .map((json) => TmdbWatchProviderDto.fromJson(json))
        .where(
          (provider) =>
              provider.logoPath != null &&
              provider.logoPath!.isNotEmpty &&
              provider.displayPriority != null,
        )
        .toList(growable: false);
  }
}
