import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/utils/title_cleaner.dart';

void main() {
  group('TitleCleaner.cleanWithYear', () {
    test('removes technical tags and extracts year', () {
      final result = TitleCleaner.cleanWithYear(
        '|FR| Top Gun Maverick 2022 4K MULTI (HDR10)',
      );

      expect(result.cleanedTitle, 'Top Gun Maverick');
      expect(result.year, 2022);
    });

    test('removes language and resolution tokens', () {
      final result = TitleCleaner.cleanWithYear(
        'The Batman 2022 VOSTFR 2160p',
      );

      expect(result.cleanedTitle, 'The Batman');
      expect(result.year, 2022);
    });

    test('handles dotted separators', () {
      final result = TitleCleaner.cleanWithYear(
        'DUNE.2021.4K.HDR.MULTI',
      );

      expect(result.cleanedTitle, 'DUNE');
      expect(result.year, 2021);
    });

    test('keeps meaningful punctuation and removes tags', () {
      final result = TitleCleaner.cleanWithYear(
        'Spider-Man: No Way Home (2021) [BluRay] x264',
      );

      expect(result.cleanedTitle, 'Spider Man: No Way Home');
      expect(result.year, 2021);
    });

    test('normalizes hyphen separators and extracts year', () {
      final result = TitleCleaner.cleanWithYear(
        'Avatar-The-Way-of-Water-2022-UHD',
      );

      expect(result.cleanedTitle, 'Avatar The Way of Water');
      expect(result.year, 2022);
    });

    test('keeps title when no year is present', () {
      final result = TitleCleaner.cleanWithYear('Heat');

      expect(result.cleanedTitle, 'Heat');
      expect(result.year, isNull);
    });
  });
}
