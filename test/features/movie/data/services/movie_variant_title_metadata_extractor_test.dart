import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/movie/data/services/movie_variant_title_metadata_extractor.dart';

void main() {
  const extractor = MovieVariantTitleMetadataExtractor();

  test(
    'extracts metadata from pipe separated language and quality markers',
    () {
      final metadata = extractor.extract('Dune Part Two |FR| |FHD| BluRay');

      expect(metadata.audioLanguageCode, 'fr');
      expect(metadata.audioLanguageLabel, 'FR');
      expect(metadata.qualityLabel, 'Full HD');
      expect(metadata.qualityRank, 3);
    },
  );

  test(
    'extracts VO and subtitles from VOST markers without using the title cleaner',
    () {
      final metadata = extractor.extract('Dune Part Two |VOST| UHD HDR10');

      expect(metadata.audioLanguageCode, isNull);
      expect(metadata.audioLanguageLabel, 'VO');
      expect(metadata.subtitleLanguageCode, isNull);
      expect(metadata.subtitleLanguageLabel, isNull);
      expect(metadata.hasSubtitles, isTrue);
      expect(metadata.qualityLabel, '4K');
      expect(metadata.qualityRank, 4);
      expect(metadata.dynamicRangeLabel, 'HDR10');
    },
  );

  test('extracts english audio and HD quality from short markers', () {
    final metadata = extractor.extract('The Matrix |EN| HD WEBRip');

    expect(metadata.audioLanguageCode, 'en');
    expect(metadata.audioLanguageLabel, 'EN');
    expect(metadata.qualityLabel, 'HD');
    expect(metadata.qualityRank, 2);
  });

  test('does not mistake DTSHD for an HD quality marker', () {
    final metadata = extractor.extract('The Matrix DTSHD MA TRUEFRENCH');

    expect(metadata.audioLanguageCode, 'fr');
    expect(metadata.audioLanguageLabel, 'FR');
    expect(metadata.qualityLabel, isNull);
    expect(metadata.qualityRank, isNull);
  });
}
