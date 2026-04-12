import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/parental/domain/services/movie_metadata_resolver.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/movie/domain/repositories/movie_repository.dart';

/// Adaptateur concret du port parental [MovieMetadataResolver].
///
/// Cette implémentation s'appuie sur le repository métier Movie plutôt que sur
/// la datasource TMDB brute afin de limiter le couplage aux détails I/O.
///
//// La stratégie est volontairement conservative :
/// - match exact normalisé unique -> accepté
/// - sinon, un seul candidat résolvable -> accepté
/// - sinon -> null
///
/// Cela évite des faux positifs tant que le port parental ne transporte pas
/// aussi l'année de sortie.
class MovieMetadataResolverAdapter implements MovieMetadataResolver {
  const MovieMetadataResolverAdapter({
    required MovieRepository repository,
    required AppLogger logger,
  }) : _repository = repository,
       _logger = logger;

  final MovieRepository _repository;
  final AppLogger _logger;

  @override
  Future<MovieMetadataResolution?> resolveByTitle(
    String normalizedTitle,
  ) async {
    final normalizedQuery = _normalize(normalizedTitle);
    if (normalizedQuery.isEmpty) {
      return null;
    }

    try {
      final results = await _repository.searchMovies(normalizedQuery);
      final resolvableCandidates = _toResolvableCandidates(results);

      if (resolvableCandidates.isEmpty) {
        return null;
      }

      final exactMatches = resolvableCandidates
          .where(
            (candidate) =>
                _normalize(candidate.summary.title.display) == normalizedQuery,
          )
          .toList(growable: false);

      if (exactMatches.length == 1) {
        return _toResolution(exactMatches.single);
      }

      if (exactMatches.length > 1) {
        _logger.warn(
          'MovieMetadataResolverAdapter ambiguous exact match for "$normalizedQuery" '
          '(${exactMatches.length} candidates).',
          category: 'parental',
        );
        return null;
      }

      if (resolvableCandidates.length == 1) {
        return _toResolution(resolvableCandidates.single);
      }

      _logger.warn(
        'MovieMetadataResolverAdapter ambiguous match for "$normalizedQuery" '
        '(${resolvableCandidates.length} candidates).',
        category: 'parental',
      );
      return null;
    } catch (error, stackTrace) {
      _logger.error(
        'MovieMetadataResolverAdapter failed for "$normalizedQuery"',
        error,
        stackTrace,
      );
      return null;
    }
  }

  List<_ResolvableMovieCandidate> _toResolvableCandidates(
    List<MovieSummary> results,
  ) {
    final candidates = <_ResolvableMovieCandidate>[];

    for (final summary in results) {
      final tmdbId = _extractTmdbId(summary);
      if (tmdbId == null || tmdbId <= 0) {
        continue;
      }

      candidates.add(
        _ResolvableMovieCandidate(summary: summary, tmdbId: tmdbId),
      );
    }

    return candidates;
  }

  int? _extractTmdbId(MovieSummary summary) {
    if (summary.tmdbId != null && summary.tmdbId! > 0) {
      return summary.tmdbId;
    }

    final parsedFromId = int.tryParse(summary.id.value);
    if (parsedFromId != null && parsedFromId > 0) {
      return parsedFromId;
    }

    return null;
  }

  MovieMetadataResolution _toResolution(_ResolvableMovieCandidate candidate) {
    return MovieMetadataResolution(
      tmdbId: candidate.tmdbId,
      matchedTitle: candidate.summary.title.display,
    );
  }

  String _normalize(String value) {
    final lowercased = value.trim().toLowerCase();
    if (lowercased.isEmpty) {
      return '';
    }

    final withoutPunctuation = lowercased.replaceAll(
      RegExp(r'[^a-z0-9]+'),
      ' ',
    );

    return withoutPunctuation.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class _ResolvableMovieCandidate {
  const _ResolvableMovieCandidate({
    required this.summary,
    required this.tmdbId,
  });

  final MovieSummary summary;
  final int tmdbId;
}
