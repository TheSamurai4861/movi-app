import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/parental/domain/services/series_metadata_resolver.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';

/// Adaptateur concret du port parental [SeriesMetadataResolver].
///
/// Cette implémentation s'appuie sur [TvRepository] plutôt que sur la
/// datasource TMDB brute afin de rester au niveau de l'API métier du module TV.
///
/// Stratégie de résolution :
/// - match exact normalisé unique -> accepté
/// - sinon, un seul candidat résolvable -> accepté
/// - sinon -> null
///
/// Le comportement est volontairement conservateur afin d'éviter les faux
/// positifs tant que le port parental ne fournit pas aussi l'année.
class SeriesMetadataResolverAdapter implements SeriesMetadataResolver {
  const SeriesMetadataResolverAdapter({
    required TvRepository repository,
    required AppLogger logger,
  }) : _repository = repository,
       _logger = logger;

  final TvRepository _repository;
  final AppLogger _logger;

  @override
  Future<SeriesMetadataResolution?> resolveByTitle(
    String normalizedTitle,
  ) async {
    final normalizedQuery = _normalize(normalizedTitle);
    if (normalizedQuery.isEmpty) {
      return null;
    }

    try {
      final results = await _repository.searchShows(normalizedQuery);
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
          'SeriesMetadataResolverAdapter ambiguous exact match for "$normalizedQuery" '
          '(${exactMatches.length} candidates).',
          category: 'parental',
        );
        return null;
      }

      if (resolvableCandidates.length == 1) {
        return _toResolution(resolvableCandidates.single);
      }

      _logger.warn(
        'SeriesMetadataResolverAdapter ambiguous match for "$normalizedQuery" '
        '(${resolvableCandidates.length} candidates).',
        category: 'parental',
      );
      return null;
    } catch (error, stackTrace) {
      _logger.error(
        'SeriesMetadataResolverAdapter failed for "$normalizedQuery"',
        error,
        stackTrace,
      );
      return null;
    }
  }

  List<_ResolvableSeriesCandidate> _toResolvableCandidates(
    List<TvShowSummary> results,
  ) {
    final candidates = <_ResolvableSeriesCandidate>[];

    for (final summary in results) {
      final tmdbId = _extractTmdbId(summary);
      if (tmdbId == null || tmdbId <= 0) {
        continue;
      }

      candidates.add(
        _ResolvableSeriesCandidate(summary: summary, tmdbId: tmdbId),
      );
    }

    return candidates;
  }

  int? _extractTmdbId(TvShowSummary summary) {
    if (summary.tmdbId != null && summary.tmdbId! > 0) {
      return summary.tmdbId;
    }

    final parsedFromId = int.tryParse(summary.id.value);
    if (parsedFromId != null && parsedFromId > 0) {
      return parsedFromId;
    }

    return null;
  }

  SeriesMetadataResolution _toResolution(_ResolvableSeriesCandidate candidate) {
    return SeriesMetadataResolution(
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

class _ResolvableSeriesCandidate {
  const _ResolvableSeriesCandidate({
    required this.summary,
    required this.tmdbId,
  });

  final TvShowSummary summary;
  final int tmdbId;
}
