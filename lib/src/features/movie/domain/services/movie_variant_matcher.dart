import 'package:movi/src/core/utils/title_cleaner.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/movie/domain/entities/movie_variant_match_result.dart';

class MovieVariantMatcher {
  const MovieVariantMatcher();

  MovieVariantMatchResult match({
    required XtreamPlaylistItem referenceItem,
    required XtreamPlaylistItem candidateItem,
  }) {
    final referenceIdentity = _MovieVariantIdentity.fromItem(referenceItem);
    final candidateIdentity = _MovieVariantIdentity.fromItem(candidateItem);
    var hasConflictingTmdbId = false;

    if (referenceItem.type != candidateItem.type) {
      return MovieVariantMatchResult(
        kind: MovieVariantMatchKind.none,
        reason: MovieVariantMatchReason.contentTypeMismatch,
        referenceTitle: referenceIdentity.cleanedTitle,
        candidateTitle: candidateIdentity.cleanedTitle,
        referenceYear: referenceIdentity.year,
        candidateYear: candidateIdentity.year,
      );
    }

    if (referenceItem.streamId == candidateItem.streamId) {
      return MovieVariantMatchResult(
        kind: MovieVariantMatchKind.strict,
        reason: MovieVariantMatchReason.sameStreamId,
        referenceTitle: referenceIdentity.cleanedTitle,
        candidateTitle: candidateIdentity.cleanedTitle,
        referenceYear: referenceIdentity.year,
        candidateYear: candidateIdentity.year,
      );
    }

    final referenceTmdbId = referenceItem.tmdbId;
    final candidateTmdbId = candidateItem.tmdbId;
    if (referenceTmdbId != null && candidateTmdbId != null) {
      if (referenceTmdbId == candidateTmdbId) {
        return MovieVariantMatchResult(
          kind: MovieVariantMatchKind.strict,
          reason: MovieVariantMatchReason.sameTmdbId,
          referenceTitle: referenceIdentity.cleanedTitle,
          candidateTitle: candidateIdentity.cleanedTitle,
          referenceYear: referenceIdentity.year,
          candidateYear: candidateIdentity.year,
        );
      }
      hasConflictingTmdbId = true;
    }

    if (!referenceIdentity.hasSignificantTitle ||
        !candidateIdentity.hasSignificantTitle) {
      return MovieVariantMatchResult(
        kind: MovieVariantMatchKind.none,
        reason: MovieVariantMatchReason.cleanTitleMissing,
        referenceTitle: referenceIdentity.cleanedTitle,
        candidateTitle: candidateIdentity.cleanedTitle,
        referenceYear: referenceIdentity.year,
        candidateYear: candidateIdentity.year,
      );
    }

    if (referenceIdentity.normalizedKey != candidateIdentity.normalizedKey) {
      return MovieVariantMatchResult(
        kind: MovieVariantMatchKind.none,
        reason: MovieVariantMatchReason.cleanTitleMismatch,
        referenceTitle: referenceIdentity.cleanedTitle,
        candidateTitle: candidateIdentity.cleanedTitle,
        referenceYear: referenceIdentity.year,
        candidateYear: candidateIdentity.year,
      );
    }

    final referenceYear = referenceIdentity.year;
    final candidateYear = candidateIdentity.year;
    if (referenceYear != null && candidateYear != null) {
      if (referenceYear == candidateYear) {
        if (hasConflictingTmdbId) {
          return MovieVariantMatchResult(
            kind: MovieVariantMatchKind.none,
            reason: MovieVariantMatchReason.conflictingTmdbId,
            referenceTitle: referenceIdentity.cleanedTitle,
            candidateTitle: candidateIdentity.cleanedTitle,
            referenceYear: referenceYear,
            candidateYear: candidateYear,
          );
        }
        return MovieVariantMatchResult(
          kind: MovieVariantMatchKind.compatible,
          reason: MovieVariantMatchReason.sameCleanTitleAndYear,
          referenceTitle: referenceIdentity.cleanedTitle,
          candidateTitle: candidateIdentity.cleanedTitle,
          referenceYear: referenceYear,
          candidateYear: candidateYear,
        );
      }

      return MovieVariantMatchResult(
        kind: MovieVariantMatchKind.none,
        reason: MovieVariantMatchReason.conflictingYear,
        referenceTitle: referenceIdentity.cleanedTitle,
        candidateTitle: candidateIdentity.cleanedTitle,
        referenceYear: referenceYear,
        candidateYear: candidateYear,
      );
    }

    if (referenceYear == null && candidateYear == null) {
      if (hasConflictingTmdbId) {
        return MovieVariantMatchResult(
          kind: MovieVariantMatchKind.none,
          reason: MovieVariantMatchReason.conflictingTmdbId,
          referenceTitle: referenceIdentity.cleanedTitle,
          candidateTitle: candidateIdentity.cleanedTitle,
          referenceYear: referenceYear,
          candidateYear: candidateYear,
        );
      }
      return MovieVariantMatchResult(
        kind: MovieVariantMatchKind.compatible,
        reason: MovieVariantMatchReason.sameCleanTitleWithoutYear,
        referenceTitle: referenceIdentity.cleanedTitle,
        candidateTitle: candidateIdentity.cleanedTitle,
        referenceYear: referenceYear,
        candidateYear: candidateYear,
      );
    }

    if (hasConflictingTmdbId) {
      return MovieVariantMatchResult(
        kind: MovieVariantMatchKind.none,
        reason: MovieVariantMatchReason.conflictingTmdbId,
        referenceTitle: referenceIdentity.cleanedTitle,
        candidateTitle: candidateIdentity.cleanedTitle,
        referenceYear: referenceYear,
        candidateYear: candidateYear,
      );
    }

    return MovieVariantMatchResult(
      kind: MovieVariantMatchKind.compatible,
      reason: MovieVariantMatchReason.sameCleanTitleWithMissingYear,
      referenceTitle: referenceIdentity.cleanedTitle,
      candidateTitle: candidateIdentity.cleanedTitle,
      referenceYear: referenceYear,
      candidateYear: candidateYear,
    );
  }
}

class _MovieVariantIdentity {
  const _MovieVariantIdentity({
    required this.cleanedTitle,
    required this.normalizedKey,
    required this.year,
    required this.hasSignificantTitle,
  });

  factory _MovieVariantIdentity.fromItem(XtreamPlaylistItem item) {
    final cleaned = TitleCleaner.cleanWithYear(item.title);
    final cleanedTitle = cleaned.cleanedTitle.trim();
    final normalizedKey = cleanedTitle.toUpperCase();
    final titleYear = cleaned.year;
    final releaseYear = item.releaseYear;
    final year = releaseYear ?? titleYear;

    return _MovieVariantIdentity(
      cleanedTitle: cleanedTitle,
      normalizedKey: normalizedKey,
      year: year,
      hasSignificantTitle: _isSignificantTitle(normalizedKey),
    );
  }

  final String cleanedTitle;
  final String normalizedKey;
  final int? year;
  final bool hasSignificantTitle;

  static bool _isSignificantTitle(String normalizedTitle) {
    if (normalizedTitle.isEmpty || normalizedTitle.length < 4) {
      return false;
    }

    final tokens = normalizedTitle
        .split(RegExp(r'\s+'))
        .where((token) => token.length >= 2)
        .toList(growable: false);
    return tokens.isNotEmpty;
  }
}
