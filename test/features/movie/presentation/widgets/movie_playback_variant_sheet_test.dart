import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/features/movie/presentation/widgets/movie_playback_variant_sheet.dart';
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

void main() {
  testWidgets(
    'shows readable partial metadata without rebuilding selection logic',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: MoviePlaybackVariantSheet(
                movieTitle: 'The Matrix',
                variants: <PlaybackVariant>[
                  PlaybackVariant(
                    id: 'source-a:1',
                    sourceId: 'source-a',
                    sourceLabel: 'Salon',
                    videoSource: const VideoSource(
                      url: 'https://video.example/1.mp4',
                      title: 'The Matrix',
                      contentId: '603',
                      contentType: ContentType.movie,
                    ),
                    contentType: ContentType.movie,
                    rawTitle: 'The.Matrix.1999.1080p.TRUEFRENCH',
                    normalizedTitle: 'The Matrix',
                    qualityLabel: 'Full HD',
                    dynamicRangeLabel: 'HDR10',
                    audioLanguageLabel: 'FR',
                  ),
                  PlaybackVariant(
                    id: 'source-b:2',
                    sourceId: 'source-b',
                    sourceLabel: 'Chambre',
                    videoSource: const VideoSource(
                      url: 'https://video.example/2.mp4',
                      title: 'The Matrix',
                      contentId: '603',
                      contentType: ContentType.movie,
                    ),
                    contentType: ContentType.movie,
                    rawTitle: 'The.Matrix.1999',
                    normalizedTitle: 'The Matrix',
                    hasSubtitles: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('The Matrix'), findsOneWidget);
      expect(find.text('Version 1'), findsOneWidget);
      expect(find.text('Version 2'), findsOneWidget);
      expect(find.text('Full HD'), findsOneWidget);
      expect(find.text('HDR10'), findsOneWidget);
      expect(find.text('FR'), findsOneWidget);
      expect(find.text('ST'), findsOneWidget);
      expect(find.text('Salon'), findsNothing);
      expect(find.text('Chambre'), findsNothing);
    },
  );

  testWidgets(
    'falls back to the source label when a variant has no useful tag',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: MoviePlaybackVariantSheet(
                movieTitle: 'The Matrix',
                variants: <PlaybackVariant>[
                  PlaybackVariant(
                    id: 'source-b:2',
                    sourceId: 'source-b',
                    sourceLabel: 'Chambre',
                    videoSource: const VideoSource(
                      url: 'https://video.example/2.mp4',
                      title: 'The Matrix',
                      contentId: '603',
                      contentType: ContentType.movie,
                    ),
                    contentType: ContentType.movie,
                    rawTitle: 'The.Matrix.1999',
                    normalizedTitle: 'The Matrix',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Chambre'), findsOneWidget);
      expect(find.text('Version 1'), findsNothing);
    },
  );

  testWidgets('shows HD labels when they are part of the useful differences', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MoviePlaybackVariantSheet(
              movieTitle: 'The Matrix',
              variants: <PlaybackVariant>[
                PlaybackVariant(
                  id: 'source-a:1',
                  sourceId: 'source-a',
                  sourceLabel: 'Salon',
                  videoSource: const VideoSource(
                    url: 'https://video.example/1.mp4',
                    title: 'The Matrix',
                    contentId: '603',
                    contentType: ContentType.movie,
                  ),
                  contentType: ContentType.movie,
                  rawTitle: 'The.Matrix.1999.|VOSTFR|.HD',
                  normalizedTitle: 'The Matrix',
                  qualityLabel: 'HD',
                  audioLanguageLabel: 'VO',
                  subtitleLanguageLabel: 'FR',
                ),
                PlaybackVariant(
                  id: 'source-b:2',
                  sourceId: 'source-b',
                  sourceLabel: 'Chambre',
                  videoSource: const VideoSource(
                    url: 'https://video.example/2.mp4',
                    title: 'The Matrix',
                    contentId: '603',
                    contentType: ContentType.movie,
                  ),
                  contentType: ContentType.movie,
                  rawTitle: 'The.Matrix.1999.TRUEFRENCH.FullHD',
                  normalizedTitle: 'The Matrix',
                  qualityLabel: 'Full HD',
                  audioLanguageLabel: 'FR',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('HD'), findsOneWidget);
    expect(find.text('VO'), findsOneWidget);
    expect(find.text('ST FR'), findsOneWidget);
    expect(find.text('Full HD'), findsOneWidget);
  });
}
