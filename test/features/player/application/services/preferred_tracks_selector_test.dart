import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/player/application/services/preferred_tracks_selector.dart';
import 'package:movi/src/features/player/domain/value_objects/track_info.dart';

void main() {
  group('PreferredTracksSelector', () {
    const selector = PreferredTracksSelector();

    test(
      'selects audio and subtitle tracks matching persisted preferences',
      () {
        final selection = selector.select(
          audioTracks: const <TrackInfo>[
            TrackInfo(type: TrackType.audio, id: 1, language: 'en'),
            TrackInfo(type: TrackType.audio, id: 2, language: 'fre'),
          ],
          subtitleTracks: const <TrackInfo>[
            TrackInfo(type: TrackType.subtitle, id: 10, title: 'English'),
            TrackInfo(type: TrackType.subtitle, id: 11, title: 'Francais'),
          ],
          preferredAudioLanguageCode: 'fr-FR',
          preferredSubtitleLanguageCode: 'fr',
        );

        expect(
          selection.audio.status,
          PreferredTrackSelectionStatus.matchFound,
        );
        expect(selection.audio.requestedTrack?.id, 2);
        expect(selection.audio.preferredLanguageCode, 'fr');

        expect(
          selection.subtitle.status,
          PreferredTrackSelectionStatus.matchFound,
        );
        expect(selection.subtitle.requestedTrack?.id, 11);
        expect(selection.subtitle.preferredLanguageCode, 'fr');
      },
    );

    test(
      'selects both preferred audio and subtitle tracks on first exposed track set',
      () {
        final selection = selector.select(
          audioTracks: const <TrackInfo>[
            TrackInfo(type: TrackType.audio, id: 1, title: 'English 5.1'),
            TrackInfo(type: TrackType.audio, id: 2, title: 'French Dolby'),
          ],
          subtitleTracks: const <TrackInfo>[
            TrackInfo(type: TrackType.subtitle, id: 10, title: 'Off'),
            TrackInfo(type: TrackType.subtitle, id: 11, title: 'English SDH'),
          ],
          preferredAudioLanguageCode: 'fr',
          preferredSubtitleLanguageCode: 'en',
        );

        expect(
          selection.audio.status,
          PreferredTrackSelectionStatus.matchFound,
        );
        expect(selection.audio.requestedTrack?.id, 2);
        expect(
          selection.subtitle.status,
          PreferredTrackSelectionStatus.matchFound,
        );
        expect(selection.subtitle.requestedTrack?.id, 11);
      },
    );

    test(
      'reports no match when tracks are present but none matches preference',
      () {
        final selection = selector.select(
          audioTracks: const <TrackInfo>[
            TrackInfo(type: TrackType.audio, id: 1, language: 'en'),
          ],
          subtitleTracks: const <TrackInfo>[
            TrackInfo(type: TrackType.subtitle, id: 10, language: 'es'),
          ],
          preferredAudioLanguageCode: 'de',
          preferredSubtitleLanguageCode: 'fr',
        );

        expect(
          selection.audio.status,
          PreferredTrackSelectionStatus.noMatchFound,
        );
        expect(selection.audio.requestedTrack, isNull);
        expect(selection.audio.preferredLanguageCode, 'de');

        expect(
          selection.subtitle.status,
          PreferredTrackSelectionStatus.noMatchFound,
        );
        expect(selection.subtitle.requestedTrack, isNull);
        expect(selection.subtitle.preferredLanguageCode, 'fr');
      },
    );

    test('disables subtitles when no subtitle preference is configured', () {
      final selection = selector.select(
        audioTracks: const <TrackInfo>[
          TrackInfo(type: TrackType.audio, id: 1, language: 'en'),
        ],
        subtitleTracks: const <TrackInfo>[
          TrackInfo(type: TrackType.subtitle, id: 10, language: 'en'),
        ],
        preferredAudioLanguageCode: null,
        preferredSubtitleLanguageCode: null,
      );

      expect(
        selection.audio.status,
        PreferredTrackSelectionStatus.noPreference,
      );
      expect(
        selection.subtitle.status,
        PreferredTrackSelectionStatus.disableRequested,
      );
    });

    test(
      'reports no tracks available when a preference exists but no track is exposed',
      () {
        final selection = selector.select(
          audioTracks: const <TrackInfo>[],
          subtitleTracks: const <TrackInfo>[],
          preferredAudioLanguageCode: 'fr',
          preferredSubtitleLanguageCode: 'en',
        );

        expect(
          selection.audio.status,
          PreferredTrackSelectionStatus.noTracksAvailable,
        );
        expect(
          selection.subtitle.status,
          PreferredTrackSelectionStatus.noTracksAvailable,
        );
      },
    );

    test('builds a stable application fingerprint for identical inputs', () {
      final firstPlan = selector.plan(
        audioTracks: const <TrackInfo>[
          TrackInfo(type: TrackType.audio, id: 1, language: 'en'),
          TrackInfo(type: TrackType.audio, id: 2, language: 'fr'),
        ],
        subtitleTracks: const <TrackInfo>[
          TrackInfo(type: TrackType.subtitle, id: 10, language: 'fr'),
        ],
        preferredAudioLanguageCode: 'fr',
        preferredSubtitleLanguageCode: 'fr',
        currentAudioTrackId: 2,
        currentSubtitleTrackId: 10,
        subtitlesEnabled: true,
        previousFingerprint: null,
      );

      final secondPlan = selector.plan(
        audioTracks: const <TrackInfo>[
          TrackInfo(type: TrackType.audio, id: 1, language: 'en'),
          TrackInfo(type: TrackType.audio, id: 2, language: 'fr'),
        ],
        subtitleTracks: const <TrackInfo>[
          TrackInfo(type: TrackType.subtitle, id: 10, language: 'fr'),
        ],
        preferredAudioLanguageCode: 'fr',
        preferredSubtitleLanguageCode: 'fr',
        currentAudioTrackId: 2,
        currentSubtitleTrackId: 10,
        subtitlesEnabled: true,
        previousFingerprint: firstPlan.fingerprint,
      );

      expect(firstPlan.shouldApply, isTrue);
      expect(secondPlan.shouldApply, isFalse);
      expect(secondPlan.fingerprint, firstPlan.fingerprint);
    });

    test('requests a reapply when the active track state changes', () {
      final initialPlan = selector.plan(
        audioTracks: const <TrackInfo>[
          TrackInfo(type: TrackType.audio, id: 1, language: 'en'),
          TrackInfo(type: TrackType.audio, id: 2, language: 'fr'),
        ],
        subtitleTracks: const <TrackInfo>[
          TrackInfo(type: TrackType.subtitle, id: 10, language: 'fr'),
        ],
        preferredAudioLanguageCode: 'fr',
        preferredSubtitleLanguageCode: 'fr',
        currentAudioTrackId: 2,
        currentSubtitleTrackId: 10,
        subtitlesEnabled: true,
        previousFingerprint: null,
      );

      final driftedPlan = selector.plan(
        audioTracks: const <TrackInfo>[
          TrackInfo(type: TrackType.audio, id: 1, language: 'en'),
          TrackInfo(type: TrackType.audio, id: 2, language: 'fr'),
        ],
        subtitleTracks: const <TrackInfo>[
          TrackInfo(type: TrackType.subtitle, id: 10, language: 'fr'),
        ],
        preferredAudioLanguageCode: 'fr',
        preferredSubtitleLanguageCode: 'fr',
        currentAudioTrackId: 1,
        currentSubtitleTrackId: null,
        subtitlesEnabled: false,
        previousFingerprint: initialPlan.fingerprint,
      );

      expect(driftedPlan.shouldApply, isTrue);
      expect(
        driftedPlan.selection.audio.status,
        PreferredTrackSelectionStatus.matchFound,
      );
      expect(driftedPlan.selection.audio.requestedTrack?.id, 2);
      expect(
        driftedPlan.selection.subtitle.status,
        PreferredTrackSelectionStatus.matchFound,
      );
      expect(driftedPlan.selection.subtitle.requestedTrack?.id, 10);
    });
  });
}
