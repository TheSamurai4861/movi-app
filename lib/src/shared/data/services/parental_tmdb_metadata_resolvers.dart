import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/parental/domain/services/movie_metadata_resolver.dart';
import 'package:movi/src/core/parental/domain/services/series_metadata_resolver.dart';
import 'package:movi/src/shared/domain/services/tmdb_id_resolver_service.dart';

typedef ResolveMovieTmdbIdByTitle = Future<int?> Function(String title);
typedef ResolveSeriesTmdbIdByTitle = Future<int?> Function(String title);

/// Adapte le resolver TMDB partagé au port parental pour les films.
///
/// On centralise ici le pont entre `core/parental` et la logique de résolution
/// TMDB déjà existante dans `shared`, afin d'éviter de dupliquer des resolvers
/// spécifiques dans les features Movie/TV.
class SharedMovieMetadataResolverAdapter implements MovieMetadataResolver {
  SharedMovieMetadataResolverAdapter({
    TmdbIdResolverService? resolver,
    required AppLogger logger,
    ResolveMovieTmdbIdByTitle? resolveMovieTmdbIdByTitle,
  }) : _resolver = resolver,
       _logger = logger,
       _resolveMovieTmdbIdByTitle = resolveMovieTmdbIdByTitle {
    assert(
      _resolver != null || _resolveMovieTmdbIdByTitle != null,
      'SharedMovieMetadataResolverAdapter requires either a TmdbIdResolverService '
      'or a resolveMovieTmdbIdByTitle callback.',
    );
  }

  final TmdbIdResolverService? _resolver;
  final AppLogger _logger;
  final ResolveMovieTmdbIdByTitle? _resolveMovieTmdbIdByTitle;

  @override
  Future<MovieMetadataResolution?> resolveByTitle(
    String normalizedTitle,
  ) async {
    final cleanedTitle = normalizedTitle.trim();
    if (cleanedTitle.isEmpty) {
      return null;
    }

    try {
      final tmdbId = await _resolveMovieTmdbId(cleanedTitle);
      if (tmdbId == null || tmdbId <= 0) {
        return null;
      }

      return MovieMetadataResolution(
        tmdbId: tmdbId,
        matchedTitle: cleanedTitle,
      );
    } catch (error, stackTrace) {
      _logger.error(
        'SharedMovieMetadataResolverAdapter failed for "$cleanedTitle"',
        error,
        stackTrace,
      );
      return null;
    }
  }

  Future<int?> _resolveMovieTmdbId(String title) {
    final resolverOverride = _resolveMovieTmdbIdByTitle;
    if (resolverOverride != null) {
      return resolverOverride(title);
    }

    final resolver = _resolver;
    if (resolver == null) {
      throw StateError(
        'SharedMovieMetadataResolverAdapter cannot resolve a TMDB id without '
        'a resolver or a resolveMovieTmdbIdByTitle callback.',
      );
    }

    return resolver.searchTmdbIdByTitleForMovie(title: title);
  }
}

/// Adapte le resolver TMDB partagé au port parental pour les séries.
///
/// Le service partagé existe déjà mais son API exacte a évolué au fil du temps.
/// On encapsule ici cette compatibilité dans un point unique plutôt que de
/// répandre cette logique dans le module parental.
class SharedSeriesMetadataResolverAdapter implements SeriesMetadataResolver {
  SharedSeriesMetadataResolverAdapter({
    TmdbIdResolverService? resolver,
    required AppLogger logger,
    ResolveSeriesTmdbIdByTitle? resolveSeriesTmdbIdByTitle,
  }) : _resolver = resolver,
       _logger = logger,
       _resolveSeriesTmdbIdByTitle = resolveSeriesTmdbIdByTitle {
    assert(
      _resolver != null || _resolveSeriesTmdbIdByTitle != null,
      'SharedSeriesMetadataResolverAdapter requires either a TmdbIdResolverService '
      'or a resolveSeriesTmdbIdByTitle callback.',
    );
  }

  final TmdbIdResolverService? _resolver;
  final AppLogger _logger;
  final ResolveSeriesTmdbIdByTitle? _resolveSeriesTmdbIdByTitle;

  @override
  Future<SeriesMetadataResolution?> resolveByTitle(
    String normalizedTitle,
  ) async {
    final cleanedTitle = normalizedTitle.trim();
    if (cleanedTitle.isEmpty) {
      return null;
    }

    try {
      final tmdbId = await _resolveSeriesTmdbId(cleanedTitle);
      if (tmdbId == null || tmdbId <= 0) {
        return null;
      }

      return SeriesMetadataResolution(
        tmdbId: tmdbId,
        matchedTitle: cleanedTitle,
      );
    } catch (error, stackTrace) {
      _logger.error(
        'SharedSeriesMetadataResolverAdapter failed for "$cleanedTitle"',
        error,
        stackTrace,
      );
      return null;
    }
  }

  Future<int?> _resolveSeriesTmdbId(String title) async {
    final resolverOverride = _resolveSeriesTmdbIdByTitle;
    if (resolverOverride != null) {
      return resolverOverride(title);
    }

    final resolver = _resolver;
    if (resolver == null) {
      throw StateError(
        'SharedSeriesMetadataResolverAdapter cannot resolve a TMDB id without '
        'a resolver or a resolveSeriesTmdbIdByTitle callback.',
      );
    }

    final dynamic dynamicResolver = resolver;

    try {
      final dynamic result = await dynamicResolver.searchTmdbIdByTitleForSeries(
        title: title,
      );
      return _normalizeTmdbId(result);
    } on NoSuchMethodError {
      final dynamic result = await dynamicResolver.searchTmdbIdByTitleForTv(
        title: title,
      );
      return _normalizeTmdbId(result);
    }
  }

  int? _normalizeTmdbId(Object? rawValue) {
    return switch (rawValue) {
      final int value when value > 0 => value,
      final num value when value > 0 => value.toInt(),
      _ => null,
    };
  }
}
