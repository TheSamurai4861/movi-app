import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/player/application/services/playback_selection_service.dart';
import 'package:movi/src/features/player/domain/entities/playback_selection_decision.dart';
import 'package:movi/src/features/player/domain/entities/playback_selection_preferences.dart';
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

void main() {
  const service = PlaybackSelectionService();
  const context = PlaybackSelectionContext(contentType: ContentType.movie);

  test('returns autoplay when a single playable variant exists', () {
    final variant = _variant(id: 'a:1', sourceId: 'a', sourceLabel: 'Salon');

    final decision = service.select(
      variants: <PlaybackVariant>[variant],
      preferences: const PlaybackSelectionPreferences(),
      context: context,
    );

    expect(decision.disposition, PlaybackSelectionDisposition.autoPlay);
    expect(decision.reason, PlaybackSelectionReason.singlePlayableVariant);
    expect(decision.selectedVariant?.id, 'a:1');
  });

  test('prefers exact audio and subtitle match before other candidates', () {
    final decision = service.select(
      variants: <PlaybackVariant>[
        _variant(
          id: 'a:1',
          sourceId: 'a',
          sourceLabel: 'Salon',
          audioLanguageCode: 'fr',
          audioLanguageLabel: 'VF',
        ),
        _variant(
          id: 'b:2',
          sourceId: 'b',
          sourceLabel: 'Chambre',
          audioLanguageCode: 'en',
          audioLanguageLabel: 'VO',
          subtitleLanguageCode: 'fr',
          subtitleLanguageLabel: 'FR',
        ),
      ],
      preferences: const PlaybackSelectionPreferences(
        preferredAudioLanguageCode: 'en',
        preferredSubtitleLanguageCode: 'fr',
      ),
      context: context,
    );

    expect(decision.disposition, PlaybackSelectionDisposition.autoPlay);
    expect(
      decision.reason,
      PlaybackSelectionReason.preferredAudioLanguageMatch,
    );
    expect(decision.selectedVariant?.id, 'b:2');
  });

  test('uses audio preference before unknown metadata when available', () {
    final decision = service.select(
      variants: <PlaybackVariant>[
        _variant(
          id: 'a:1',
          sourceId: 'a',
          sourceLabel: 'Salon',
          audioLanguageCode: 'fr',
          audioLanguageLabel: 'FR',
        ),
        _variant(id: 'b:2', sourceId: 'b', sourceLabel: 'Chambre'),
      ],
      preferences: const PlaybackSelectionPreferences(
        preferredAudioLanguageCode: 'fr',
      ),
      context: context,
    );

    expect(decision.disposition, PlaybackSelectionDisposition.autoPlay);
    expect(
      decision.reason,
      PlaybackSelectionReason.preferredAudioLanguageMatch,
    );
    expect(decision.selectedVariant?.id, 'a:1');
  });

  test('falls back deterministically to the best known quality', () {
    final decision = service.select(
      variants: <PlaybackVariant>[
        _variant(
          id: 'a:1',
          sourceId: 'a',
          sourceLabel: 'Salon',
          qualityLabel: 'Full HD',
          qualityRank: 3,
        ),
        _variant(id: 'b:2', sourceId: 'b', sourceLabel: 'Chambre'),
      ],
      preferences: const PlaybackSelectionPreferences(),
      context: context,
    );

    expect(decision.disposition, PlaybackSelectionDisposition.autoPlay);
    expect(decision.reason, PlaybackSelectionReason.deterministicFallback);
    expect(decision.selectedVariant?.id, 'a:1');
  });

  test('prefers the configured quality when several known variants exist', () {
    final decision = service.select(
      variants: <PlaybackVariant>[
        _variant(
          id: 'a:1',
          sourceId: 'a',
          sourceLabel: 'Salon',
          qualityLabel: 'HD',
          qualityRank: 2,
        ),
        _variant(
          id: 'b:2',
          sourceId: 'b',
          sourceLabel: 'Chambre',
          qualityLabel: '4K',
          qualityRank: 4,
        ),
      ],
      preferences: const PlaybackSelectionPreferences(preferredQualityRank: 4),
      context: context,
    );

    expect(decision.disposition, PlaybackSelectionDisposition.autoPlay);
    expect(decision.reason, PlaybackSelectionReason.preferredQualityMatch);
    expect(decision.selectedVariant?.id, 'b:2');
  });

  test(
    'ranks multiple 4K HD VF VO variants deterministically when no preference is set',
    () {
      final decision = service.select(
        variants: <PlaybackVariant>[
          _variant(
            id: 'vf-hd',
            sourceId: 'a',
            sourceLabel: 'Salon',
            qualityLabel: 'HD',
            qualityRank: 2,
            audioLanguageCode: 'fr',
            audioLanguageLabel: 'VF',
          ),
          _variant(
            id: 'vo-4k',
            sourceId: 'b',
            sourceLabel: 'Chambre',
            qualityLabel: '4K',
            qualityRank: 4,
            audioLanguageCode: 'en',
            audioLanguageLabel: 'VO',
          ),
          _variant(
            id: 'vf-fhd',
            sourceId: 'c',
            sourceLabel: 'Cuisine',
            qualityLabel: 'Full HD',
            qualityRank: 3,
            audioLanguageCode: 'fr',
            audioLanguageLabel: 'VF',
          ),
        ],
        preferences: const PlaybackSelectionPreferences(),
        context: context,
      );

      expect(decision.disposition, PlaybackSelectionDisposition.autoPlay);
      expect(decision.reason, PlaybackSelectionReason.deterministicFallback);
      expect(decision.selectedVariant?.id, 'vo-4k');
      expect(decision.rankedVariants.map((variant) => variant.id), <String>[
        'vo-4k',
        'vf-fhd',
        'vf-hd',
      ]);
    },
  );

  test(
    'prefers a lower but matching quality threshold over unknown metadata when configured',
    () {
      final decision = service.select(
        variants: <PlaybackVariant>[
          _variant(
            id: 'known-hd',
            sourceId: 'a',
            sourceLabel: 'Salon',
            qualityLabel: 'HD',
            qualityRank: 2,
            audioLanguageCode: 'fr',
            audioLanguageLabel: 'VF',
          ),
          _variant(
            id: 'unknown',
            sourceId: 'b',
            sourceLabel: 'Chambre',
            audioLanguageCode: 'fr',
            audioLanguageLabel: 'VF',
          ),
        ],
        preferences: const PlaybackSelectionPreferences(
          preferredQualityRank: 2,
        ),
        context: context,
      );

      expect(decision.disposition, PlaybackSelectionDisposition.autoPlay);
      expect(decision.reason, PlaybackSelectionReason.preferredQualityMatch);
      expect(decision.selectedVariant?.id, 'known-hd');
    },
  );

  test(
    'falls back to manual selection when no variant satisfies explicit track preferences',
    () {
      final decision = service.select(
        variants: <PlaybackVariant>[
          _variant(
            id: 'vf-4k',
            sourceId: 'a',
            sourceLabel: 'Salon',
            qualityLabel: '4K',
            qualityRank: 4,
            audioLanguageCode: 'fr',
            audioLanguageLabel: 'VF',
          ),
          _variant(
            id: 'vo-no-sub',
            sourceId: 'b',
            sourceLabel: 'Chambre',
            qualityLabel: 'Full HD',
            qualityRank: 3,
            audioLanguageCode: 'en',
            audioLanguageLabel: 'VO',
          ),
        ],
        preferences: const PlaybackSelectionPreferences(
          preferredAudioLanguageCode: 'en',
          preferredSubtitleLanguageCode: 'fr',
          preferredQualityRank: 4,
        ),
        context: context,
      );

      expect(
        decision.disposition,
        PlaybackSelectionDisposition.manualSelection,
      );
      expect(
        decision.reason,
        PlaybackSelectionReason.preferredVariantUnavailable,
      );
      expect(decision.selectedVariant, isNull);
    },
  );

  test('asks for manual selection when top variants remain ambiguous', () {
    final decision = service.select(
      variants: <PlaybackVariant>[
        _variant(id: 'b:2', sourceId: 'b', sourceLabel: 'Chambre'),
        _variant(id: 'a:1', sourceId: 'a', sourceLabel: 'Salon'),
      ],
      preferences: const PlaybackSelectionPreferences(),
      context: context,
    );

    expect(decision.disposition, PlaybackSelectionDisposition.manualSelection);
    expect(decision.reason, PlaybackSelectionReason.ambiguousVariants);
    expect(decision.selectedVariant, isNull);
    expect(decision.rankedVariants, hasLength(2));
  });
}

PlaybackVariant _variant({
  required String id,
  required String sourceId,
  required String sourceLabel,
  String? qualityLabel,
  int? qualityRank,
  String? audioLanguageCode,
  String? audioLanguageLabel,
  String? subtitleLanguageCode,
  String? subtitleLanguageLabel,
  bool? hasSubtitles,
}) {
  return PlaybackVariant(
    id: id,
    sourceId: sourceId,
    sourceLabel: sourceLabel,
    videoSource: const VideoSource(
      url: 'https://video.example/stream.mp4',
      title: 'Inception',
      contentId: '603',
      contentType: ContentType.movie,
    ),
    contentType: ContentType.movie,
    rawTitle: 'Inception',
    normalizedTitle: 'Inception',
    qualityLabel: qualityLabel,
    qualityRank: qualityRank,
    audioLanguageCode: audioLanguageCode,
    audioLanguageLabel: audioLanguageLabel,
    subtitleLanguageCode: subtitleLanguageCode,
    subtitleLanguageLabel: subtitleLanguageLabel,
    hasSubtitles: hasSubtitles,
  );
}
