import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/playback/media_kit_subtitle_text_scale.dart';
import 'package:movi/src/core/preferences/playback_sync_offset_preferences.dart';
import 'package:movi/src/core/preferences/subtitle_appearance_preferences.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/features/player/presentation/providers/player_providers.dart';
import 'package:movi/src/features/settings/presentation/pages/settings_subtitles_page.dart';

/// Reproduit la chaîne de largeurs jusqu’au `LayoutBuilder` de l’aperçu :
/// [SettingsContentWidth] plafonne à 800, padding page 20, carte section 16,
/// puis padding du container de l’aperçu 12 (×2 chaque fois).
double _expectedInnerVideoWidth(double mediaQueryWidth) {
  const maxContentWidth = 800.0;
  const pageHorizontalPadding = 20.0;
  const sectionCardPadding = 16.0;
  const previewContainerPadding = 12.0;

  final contentW = mediaQueryWidth > maxContentWidth
      ? maxContentWidth
      : mediaQueryWidth;
  final afterPage = contentW - 2 * pageHorizontalPadding;
  final previewParentW = afterPage - 2 * sectionCardPadding;
  return (previewParentW - 2 * previewContainerPadding)
      .clamp(0.0, double.infinity);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsSubtitlesPage subtitle preview scale', () {
    testWidgets('portrait: sample Text uses base fontSize and media_kit scaler',
        (tester) async {
      const size = Size(400, 800);
      await _pumpPage(tester, size);

      final l10n = _l10n(tester);
      final finder = find.text(l10n.settingsSubtitlesPreviewSample);
      expect(finder, findsOneWidget);

      final text = tester.widget<Text>(finder);
      const prefs = SubtitleAppearancePrefs.defaults;
      expect(text.style?.fontSize, prefs.toFontSize());

      final innerW = _expectedInnerVideoWidth(size.width);
      final innerH = innerW * 9 / 16;
      final expectedFactor = MediaKitSubtitleTextScale.linearFactor(
        layoutWidth: innerW,
        layoutHeight: innerH,
      );
      expect(text.textScaler!.scale(1.0), closeTo(expectedFactor, 1e-12));
    });

    testWidgets('landscape: sample Text uses media_kit scaler for wide width',
        (tester) async {
      const size = Size(800, 400);
      await _pumpPage(tester, size);

      final l10n = _l10n(tester);
      final finder = find.text(l10n.settingsSubtitlesPreviewSample);
      expect(finder, findsOneWidget);

      final text = tester.widget<Text>(finder);
      expect(
        text.style?.fontSize,
        SubtitleAppearancePrefs.defaults.toFontSize(),
      );

      final innerW = _expectedInnerVideoWidth(size.width);
      final innerH = innerW * 9 / 16;
      final expectedFactor = MediaKitSubtitleTextScale.linearFactor(
        layoutWidth: innerW,
        layoutHeight: innerH,
      );
      expect(text.textScaler!.scale(1.0), closeTo(expectedFactor, 1e-12));
    });
  });
}

Future<void> _pumpPage(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
}

AppLocalizations _l10n(WidgetTester tester) {
  return AppLocalizations.of(
    tester.element(find.byType(SettingsSubtitlesPage)),
  )!;
}
