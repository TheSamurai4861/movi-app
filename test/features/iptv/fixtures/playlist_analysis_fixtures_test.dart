import 'package:flutter_test/flutter_test.dart';

import 'playlist_analysis_fixtures.dart';

void main() {
  test('covers the representative IPTV playlist cases required by P0/03', () {
    expect(representativePlaylistAnalysisFixtures.length, 6);

    final categories = representativePlaylistAnalysisFixtures
        .map((fixture) => fixture.category)
        .toSet();
    expect(
      categories,
      containsAll(<PlaylistFixtureCategory>{
        PlaylistFixtureCategory.clean,
        PlaylistFixtureCategory.missingTmdb,
        PlaylistFixtureCategory.noisyTitle,
        PlaylistFixtureCategory.missingImages,
        PlaylistFixtureCategory.partialMetadata,
        PlaylistFixtureCategory.inconsistentMetadata,
      }),
    );

    final providers = representativePlaylistAnalysisFixtures
        .map((fixture) => fixture.provider)
        .toSet();
    expect(
      providers,
      containsAll(<PlaylistFixtureProvider>{
        PlaylistFixtureProvider.xtream,
        PlaylistFixtureProvider.stalker,
      }),
    );
  });

  test('documents a deterministic fallback posture for every fixture', () {
    for (final fixture in representativePlaylistAnalysisFixtures) {
      expect(fixture.rawFields, isNotEmpty, reason: fixture.id);
      expect(fixture.playlist.items, hasLength(1), reason: fixture.id);

      if (fixture.supportLevel == PlaylistSupportLevel.unsupported) {
        expect(fixture.normalizedTitleCandidates, isEmpty, reason: fixture.id);
        expect(
          fixture.enrichmentExpectation,
          PlaylistEnrichmentExpectation.notPossible,
          reason: fixture.id,
        );
        expect(
          fixture.uiFallback.detailAvailability,
          PlaylistDetailAvailability.hidden,
          reason: fixture.id,
        );
        continue;
      }

      expect(fixture.item.title.trim(), isNotEmpty, reason: fixture.id);
      expect(fixture.normalizedTitleCandidates, isNotEmpty, reason: fixture.id);
      expect(
        fixture.uiFallback.detailAvailability,
        isNot(PlaylistDetailAvailability.hidden),
        reason: fixture.id,
      );
    }
  });
}
