import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/parental/domain/entities/parental_content_candidate.dart';
import 'package:movi/src/features/iptv/application/services/iptv_playlist_analysis_service.dart';
import 'package:movi/src/features/iptv/data/mappers/iptv_parental_content_candidate_mapper.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';

void main() {
  group('IptvParentalContentCandidateMapper', () {
    const analysisService = IptvPlaylistAnalysisService();
    const mapper = IptvParentalContentCandidateMapper(analysisService);

    test('mappe un film exploitable vers un candidat parental', () {
      const item = XtreamPlaylistItem(
        accountId: 'source-1',
        categoryId: 'movies',
        categoryName: 'Films',
        streamId: 100,
        title: 'The Matrix',
        type: XtreamPlaylistItemType.movie,
        tmdbId: 603,
        releaseYear: 1999,
      );

      final candidate = mapper.map(item);

      expect(candidate, isNotNull);
      expect(candidate!.kind, ParentalContentCandidateKind.movie);
      expect(candidate.title, 'The Matrix');
      expect(candidate.tmdbId, 603);
      expect(candidate.normalizedTitle, isNotEmpty);
    });

    test('ignore un item sans titre exploitable', () {
      const item = XtreamPlaylistItem(
        accountId: 'source-1',
        categoryId: 'series',
        categoryName: 'Séries',
        streamId: 200,
        title: '',
        type: XtreamPlaylistItemType.series,
      );

      final candidate = mapper.map(item);

      expect(candidate, isNull);
    });
  });
}