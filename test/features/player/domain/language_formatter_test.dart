import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/player/domain/utils/language_formatter.dart';

void main() {
  group('LanguageFormatter', () {
    test('formatLanguageCode returns French label for fr', () {
      expect(LanguageFormatter.formatLanguageCode('fr'), 'Français');
    });

    test('formatLanguageCode returns English label for en', () {
      expect(LanguageFormatter.formatLanguageCode('en'), 'Anglais');
    });

    test('formatLanguageCodeWithRegion returns language when region matches code', () {
      expect(LanguageFormatter.formatLanguageCodeWithRegion('fr-FR'), 'Français');
    });

    test('normalizeLanguageCode handles variants', () {
      expect(LanguageFormatter.normalizeLanguageCode('FR_fr'), 'fr');
      expect(LanguageFormatter.normalizeLanguageCode('en-UK'), 'en');
      expect(LanguageFormatter.normalizeLanguageCode(' pt BR '), 'pt');
    });

    test('detectLanguageCodeFromTitle finds language from title hints', () {
      expect(LanguageFormatter.detectLanguageCodeFromTitle('Audio Français'), 'fr');
      expect(LanguageFormatter.detectLanguageCodeFromTitle('English subs'), 'en');
      expect(LanguageFormatter.detectLanguageCodeFromTitle('Spanish - ES'), 'es');
    });
  });
}