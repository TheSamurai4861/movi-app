import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/features/player/presentation/widgets/video_player_controls.dart';

void main() {
  testWidgets('progress slider forwards pointer interactions to onSeek', (
    tester,
  ) async {
    double? seekValue;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox.expand(
              child: VideoPlayerControls(
                title: 'Example movie',
                isPlaying: true,
                position: const Duration(minutes: 15),
                duration: const Duration(hours: 1),
                hasSubtitles: true,
                subtitlesEnabled: true,
                onBack: () {},
                onPlayPause: () {},
                onSeekForward10: () {},
                onSeekForward30: () {},
                onSeekBackward10: () {},
                onSeekBackward30: () {},
                onSeek: (value) => seekValue = value,
                onToggleSubtitles: () {},
                formatDuration: (duration) => duration.toString(),
                requestEntryFocus: false,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final sliderFinder = find.byType(Slider);
    expect(sliderFinder, findsOneWidget);

    final sliderRect = tester.getRect(sliderFinder);
    await tester.tapAt(
      Offset(sliderRect.left + sliderRect.width * 0.75, sliderRect.center.dy),
    );
    await tester.pumpAndSettle();

    expect(seekValue, isNotNull);
    expect(seekValue!, greaterThan(0.6));
  });

  testWidgets('player icon actions use circular focus backgrounds', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox.expand(
              child: VideoPlayerControls(
                title: 'Example movie',
                isPlaying: true,
                position: const Duration(minutes: 15),
                duration: const Duration(hours: 1),
                hasSubtitles: true,
                subtitlesEnabled: true,
                onBack: () {},
                onPlayPause: () {},
                onSeekForward10: () {},
                onSeekForward30: () {},
                onSeekBackward10: () {},
                onSeekBackward30: () {},
                onSeek: (_) {},
                onToggleSubtitles: () {},
                formatDuration: (duration) => duration.toString(),
                requestEntryFocus: false,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final focusFrames = tester.widgetList<MoviFocusFrame>(
      find.byType(MoviFocusFrame),
    );

    expect(focusFrames.any((frame) => frame.shape == BoxShape.circle), isTrue);
  });
}
