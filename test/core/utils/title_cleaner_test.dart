import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/utils/title_cleaner.dart';

void main() {
  test('clean removes IPTV noise tokens and keeps meaningful title tokens', () {
    final cleaned = TitleCleaner.clean(
      'The.Matrix.1999.MULTi.TRUEFRENCH.1080p.BluRay.x264',
    );

    expect(cleaned, 'The Matrix 1999');
  });

  test('cleanWithYear extracts a valid trailing year after normalization', () {
    final cleaned = TitleCleaner.cleanWithYear('Avatar [2009] - FR');

    expect(cleaned.cleanedTitle, 'Avatar');
    expect(cleaned.year, 2009);
  });

  test('cleanWithYear keeps title data when no valid year is present', () {
    final cleaned = TitleCleaner.cleanWithYear('Shogun.S01E01.VOSTFR');

    expect(cleaned.cleanedTitle, 'Shogun S01E01');
    expect(cleaned.year, isNull);
  });
}
