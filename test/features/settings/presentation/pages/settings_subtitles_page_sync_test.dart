import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/preferences/playback_sync_offset_preferences.dart';
import 'package:movi/src/core/preferences/subtitle_appearance_preferences.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/features/player/presentation/providers/player_providers.dart';
import 'package:movi/src/features/settings/presentation/pages/settings_subtitles_page.dart';

void main() {
  testWidgets(
    'SettingsSubtitlesPage affiche section sync et fallback non-support',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            asp.currentProfileSubtitleAppearanceProvider.overrideWithValue(
              SubtitleAppearancePrefs.defaults,
            ),
            asp.currentAccentColorProvider.overrideWithValue(
              const Color(0xFF2160AB),
            ),
            asp.currentProfilePlaybackSyncOffsetsProvider.overrideWithValue(
              PlaybackSyncOffsets.defaults,
            ),
            subtitleOffsetSupportProvider.overrideWith((ref) async => false),
            audioOffsetSupportProvider.overrideWith((ref) async => false),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SettingsSubtitlesPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(SettingsSubtitlesPage)),
      )!;

      expect(find.text(l10n.settingsSyncSectionTitle), findsOneWidget);
      expect(
        find.textContaining(l10n.settingsSubtitleOffsetTitle),
        findsOneWidget,
      );
      expect(
        find.textContaining(l10n.settingsAudioOffsetTitle),
        findsOneWidget,
      );
      expect(find.text(l10n.settingsOffsetUnsupported), findsNWidgets(2));
    },
  );
}
