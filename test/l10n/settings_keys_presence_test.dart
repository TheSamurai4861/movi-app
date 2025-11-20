import 'package:flutter_test/flutter_test.dart';

import 'package:movi/l10n/app_localizations_en.dart';
import 'package:movi/l10n/app_localizations_fr.dart';

void main() {
  group('Settings i18n keys presence', () {
    test('French translations expose non-empty strings', () {
      final fr = AppLocalizationsFr('fr');
      expect(fr.settingsTitle.isNotEmpty, isTrue);
      expect(fr.settingsAccountsSection.isNotEmpty, isTrue);
      expect(fr.settingsIptvSection.isNotEmpty, isTrue);
      expect(fr.settingsSourcesManagement.isNotEmpty, isTrue);
      expect(fr.settingsSyncFrequency.isNotEmpty, isTrue);
      expect(fr.settingsAppSection.isNotEmpty, isTrue);
      expect(fr.settingsAccentColor.isNotEmpty, isTrue);
      expect(fr.settingsPlaybackSection.isNotEmpty, isTrue);
      expect(fr.settingsPreferredAudioLanguage.isNotEmpty, isTrue);
      expect(fr.settingsPreferredSubtitleLanguage.isNotEmpty, isTrue);
      expect(fr.settingsLanguageLabel.isNotEmpty, isTrue);
    });

    test('English translations expose non-empty strings', () {
      final en = AppLocalizationsEn('en');
      expect(en.settingsTitle.isNotEmpty, isTrue);
      expect(en.settingsAccountsSection.isNotEmpty, isTrue);
      expect(en.settingsIptvSection.isNotEmpty, isTrue);
      expect(en.settingsSourcesManagement.isNotEmpty, isTrue);
      expect(en.settingsSyncFrequency.isNotEmpty, isTrue);
      expect(en.settingsAppSection.isNotEmpty, isTrue);
      expect(en.settingsAccentColor.isNotEmpty, isTrue);
      expect(en.settingsPlaybackSection.isNotEmpty, isTrue);
      expect(en.settingsPreferredAudioLanguage.isNotEmpty, isTrue);
      expect(en.settingsPreferredSubtitleLanguage.isNotEmpty, isTrue);
      expect(en.settingsLanguageLabel.isNotEmpty, isTrue);
      expect(en.settingsRefreshIptvPlaylistsTitle.isNotEmpty, isTrue);
    });
  });
}