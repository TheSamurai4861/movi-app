import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/iptv/application/services/iptv_playlist_fallback_policy.dart';

import '../../fixtures/playlist_analysis_fixtures.dart';

void main() {
  const policy = IptvPlaylistFallbackPolicy();

  test(
    'enforces the minimum usable contract for representative IPTV fixtures',
    () {
      for (final fixture in representativePlaylistAnalysisFixtures) {
        final result = policy.evaluate(fixture.item);

        if (fixture.supportLevel == PlaylistSupportLevel.unsupported) {
          expect(result.contract.isSatisfied, isFalse, reason: fixture.id);
          expect(
            result.disposition,
            IptvFallbackDisposition.unsupportedData,
            reason: fixture.id,
          );
          continue;
        }

        expect(result.contract.hasMeaningfulTitle, isTrue, reason: fixture.id);
        expect(
          result.contract.hasReliableContentType,
          isTrue,
          reason: fixture.id,
        );
        expect(
          result.contract.hasStableSourceIdentifier,
          isTrue,
          reason: fixture.id,
        );
        expect(result.contract.isSatisfied, isTrue, reason: fixture.id);
      }
    },
  );

  test('maps representative fixtures to a deterministic fallback policy', () {
    expect(
      policy.evaluate(_fixture('xtream_clean_movie').item),
      _matches(
        disposition: IptvFallbackDisposition.ready,
        posterDecision: IptvPosterFallbackDecision.keepSourcePoster,
        synopsisDecision: IptvSynopsisFallbackDecision.keepSourceSynopsis,
        yearDecision: IptvYearFallbackDecision.keepSourceYear,
        ratingDecision: IptvRatingFallbackDecision.keepSourceRating,
        tmdbDecision: IptvTmdbFallbackDecision.keepProvidedTmdbId,
      ),
    );

    expect(
      policy.evaluate(_fixture('xtream_missing_tmdb_movie').item),
      _matches(
        disposition: IptvFallbackDisposition.partialData,
        posterDecision: IptvPosterFallbackDecision.keepSourcePoster,
        synopsisDecision: IptvSynopsisFallbackDecision.genericUnavailable,
        yearDecision: IptvYearFallbackDecision.keepSourceYear,
        ratingDecision: IptvRatingFallbackDecision.keepSourceRating,
        tmdbDecision: IptvTmdbFallbackDecision.searchByTitleAndYear,
      ),
    );

    expect(
      policy.evaluate(_fixture('xtream_noisy_title_movie').item),
      _matches(
        disposition: IptvFallbackDisposition.partialData,
        posterDecision: IptvPosterFallbackDecision.placeholder,
        synopsisDecision: IptvSynopsisFallbackDecision.genericUnavailable,
        yearDecision: IptvYearFallbackDecision.inferFromTitle,
        ratingDecision: IptvRatingFallbackDecision.hideRating,
        tmdbDecision: IptvTmdbFallbackDecision.searchByTitleAndYear,
      ),
    );

    expect(
      policy.evaluate(_fixture('stalker_missing_images_series').item),
      _matches(
        disposition: IptvFallbackDisposition.partialData,
        posterDecision: IptvPosterFallbackDecision.fetchFromTmdb,
        synopsisDecision: IptvSynopsisFallbackDecision.keepSourceSynopsis,
        yearDecision: IptvYearFallbackDecision.keepSourceYear,
        ratingDecision: IptvRatingFallbackDecision.keepSourceRating,
        tmdbDecision: IptvTmdbFallbackDecision.keepProvidedTmdbId,
      ),
    );

    expect(
      policy.evaluate(_fixture('stalker_partial_metadata_series').item),
      _matches(
        disposition: IptvFallbackDisposition.partialData,
        posterDecision: IptvPosterFallbackDecision.placeholder,
        synopsisDecision: IptvSynopsisFallbackDecision.genericUnavailable,
        yearDecision: IptvYearFallbackDecision.keepSourceYear,
        ratingDecision: IptvRatingFallbackDecision.hideRating,
        tmdbDecision: IptvTmdbFallbackDecision.searchByTitleAndYear,
      ),
    );
  });

  test('separates technical failure from acceptable partial data', () {
    final item = _fixture('stalker_missing_images_series').item;

    final degradedData = policy.evaluate(item, tmdbLookupAvailable: true);
    final technicalFailure = policy.evaluate(item, tmdbLookupAvailable: false);

    expect(degradedData.disposition, IptvFallbackDisposition.partialData);
    expect(
      technicalFailure.disposition,
      IptvFallbackDisposition.technicalFailure,
    );
    expect(
      technicalFailure.posterDecision,
      IptvPosterFallbackDecision.placeholder,
    );
  });
}

PlaylistAnalysisFixture _fixture(String id) {
  return representativePlaylistAnalysisFixtures.firstWhere(
    (fixture) => fixture.id == id,
  );
}

Matcher _matches({
  required IptvFallbackDisposition disposition,
  required IptvPosterFallbackDecision posterDecision,
  required IptvSynopsisFallbackDecision synopsisDecision,
  required IptvYearFallbackDecision yearDecision,
  required IptvRatingFallbackDecision ratingDecision,
  required IptvTmdbFallbackDecision tmdbDecision,
}) {
  return isA<IptvPlaylistFallbackResult>()
      .having((r) => r.disposition, 'disposition', disposition)
      .having((r) => r.posterDecision, 'posterDecision', posterDecision)
      .having((r) => r.synopsisDecision, 'synopsisDecision', synopsisDecision)
      .having((r) => r.yearDecision, 'yearDecision', yearDecision)
      .having((r) => r.ratingDecision, 'ratingDecision', ratingDecision)
      .having((r) => r.tmdbDecision, 'tmdbDecision', tmdbDecision);
}
