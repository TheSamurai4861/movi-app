import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/state/device_capabilities_provider.dart';
import 'package:movi/src/core/widgets/movi_tv_action_menu.dart';
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/features/tv/presentation/widgets/episode_playback_variant_sheet.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

void main() {
  testWidgets('show uses TV/desktop modal on large screens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [isTelevisionDeviceProvider.overrideWith((ref) => true)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    unawaited(
                      EpisodePlaybackVariantSheet.show(
                        context,
                        episodeTitle: 'S01E01',
                        variants: <PlaybackVariant>[
                          PlaybackVariant(
                            id: 'source-a:1',
                            sourceId: 'source-a',
                            sourceLabel: 'Salon',
                            videoSource: const VideoSource(
                              url: 'https://video.example/1.mp4',
                              title: 'Episode',
                              contentId: '603',
                              contentType: ContentType.series,
                            ),
                            contentType: ContentType.series,
                            rawTitle: 'Episode.S01E01.1080p',
                            normalizedTitle: 'Episode',
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(MoviTvActionMenuDialog), findsOneWidget);
    expect(find.byType(EpisodePlaybackVariantSheet), findsNothing);
  });

  testWidgets('show keeps Cupertino sheet on mobile layout', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    unawaited(
                      EpisodePlaybackVariantSheet.show(
                        context,
                        episodeTitle: 'S01E01',
                        variants: <PlaybackVariant>[
                          PlaybackVariant(
                            id: 'source-a:1',
                            sourceId: 'source-a',
                            sourceLabel: 'Salon',
                            videoSource: const VideoSource(
                              url: 'https://video.example/1.mp4',
                              title: 'Episode',
                              contentId: '603',
                              contentType: ContentType.series,
                            ),
                            contentType: ContentType.series,
                            rawTitle: 'Episode.S01E01.1080p',
                            normalizedTitle: 'Episode',
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(EpisodePlaybackVariantSheet), findsOneWidget);
    expect(find.byType(MoviTvActionMenuDialog), findsNothing);
  });
}
