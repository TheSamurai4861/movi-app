import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/features/player/domain/value_objects/track_info.dart';
import 'package:movi/src/features/player/presentation/widgets/track_selection_menu.dart';

void main() {
  group('Track selection menus', () {
    testWidgets(
      'subtitle sheet displays settings action and no quick settings block',
      (tester) async {
        final tracks = <TrackInfo>[
          const TrackInfo(type: TrackType.subtitle, id: 1, title: 'FR'),
        ];

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SubtitleTrackSelectionMenu(
                tracks: tracks,
                currentTrack: tracks.first,
                onTrackSelected: (_) async {},
                onDisable: () async {},
                onOpenSubtitleSettings: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(SubtitleTrackSelectionMenu)),
        )!;

        expect(find.text(l10n.actionDisable), findsOneWidget);
        expect(find.text('FR'), findsOneWidget);
        expect(
          find.text(l10n.settingsSubtitlesQuickSettingsTitle),
          findsNothing,
        );
        expect(find.byIcon(Icons.close), findsOneWidget);
      },
    );

    testWidgets('audio sheet does not display offset quick controls', (
      tester,
    ) async {
      final tracks = <TrackInfo>[
        const TrackInfo(type: TrackType.audio, id: 1, title: 'EN'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AudioTrackSelectionMenu(
              tracks: tracks,
              currentTrack: tracks.first,
              onTrackSelected: (_) async {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(AudioTrackSelectionMenu)),
      )!;

      expect(find.text('EN'), findsOneWidget);
      expect(find.text(l10n.settingsAudioOffsetTitle), findsNothing);
    });
  });
}
