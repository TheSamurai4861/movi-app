import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/iptv/application/services/iptv_playlist_analysis_service.dart';
import 'package:movi/src/features/iptv/application/services/iptv_playlist_fallback_policy.dart';

import '../../fixtures/playlist_analysis_fixtures.dart';

void main() {
  const service = IptvPlaylistAnalysisService();

  test(
    'produces an explicit analysis object for a degraded but supported item',
    () {
      final fixture = _fixture('xtream_missing_tmdb_movie');

      final analysis = service.analyze(fixture.item);

      expect(analysis.sourceItem, fixture.item);
      expect(analysis.displayTitle, 'Inception');
      expect(analysis.normalizedYear, 2010);
      expect(
        analysis.fallback.disposition,
        IptvFallbackDisposition.partialData,
      );
      expect(
        analysis.diagnostics,
        contains(IptvPlaylistDiagnosticCode.tmdbIdentifierUnavailable),
      );
      expect(
        analysis.diagnostics,
        contains(IptvPlaylistDiagnosticCode.sourceSynopsisUnavailable),
      );
      expect(
        analysis.diagnostics,
        isNot(contains(IptvPlaylistDiagnosticCode.missingMeaningfulTitle)),
      );
    },
  );

  test('flags unsupported data when the minimum contract is not met', () {
    final fixture = _fixture('xtream_inconsistent_unsupported');

    final analysis = service.analyze(fixture.item);

    expect(
      analysis.fallback.disposition,
      IptvFallbackDisposition.unsupportedData,
    );
    expect(
      analysis.diagnostics,
      contains(IptvPlaylistDiagnosticCode.missingMeaningfulTitle),
    );
    expect(
      analysis.diagnostics,
      contains(IptvPlaylistDiagnosticCode.missingStableSourceIdentifier),
    );
  });

  test('separates technical lookup failure from partial source data', () {
    final fixture = _fixture('stalker_missing_images_series');

    final analysis = service.analyze(
      fixture.item,
      context: const IptvPlaylistAnalysisContext(tmdbLookupAvailable: false),
    );

    expect(
      analysis.fallback.disposition,
      IptvFallbackDisposition.technicalFailure,
    );
    expect(
      analysis.diagnostics,
      contains(IptvPlaylistDiagnosticCode.externalLookupUnavailable),
    );
    expect(
      analysis.diagnostics,
      contains(IptvPlaylistDiagnosticCode.sourcePosterUnavailable),
    );
  });
}

PlaylistAnalysisFixture _fixture(String id) {
  return representativePlaylistAnalysisFixtures.firstWhere(
    (fixture) => fixture.id == id,
  );
}
