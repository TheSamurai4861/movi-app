import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
import 'package:movi/src/features/tv/domain/entities/episode_playback_season_snapshot.dart';
import 'package:movi/src/features/tv/domain/usecases/resolve_series_playback_target.dart';
import 'package:movi/src/shared/domain/services/media_resume_decision.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

void main() {
  const useCase = ResolveSeriesPlaybackTarget();

  test('returns the canonical resume target when the episode still exists', () {
    final plan = useCase(
      seriesId: '100088',
      seasonSnapshots: <EpisodePlaybackSeasonSnapshot>[
        EpisodePlaybackSeasonSnapshot.fromEpisodeNumbers(
          seasonNumber: 1,
          episodeNumbers: const <int>[1, 2, 3, 4],
        ),
      ],
      resumeState: const PlaybackHistoryEntry(
        contentId: '100088',
        type: ContentType.series,
        title: 'The Last of Us',
        season: 1,
        episode: 3,
        lastPosition: Duration(minutes: 11),
        duration: Duration(minutes: 52),
      ),
    );

    expect(plan, isNotNull);
    expect(plan?.targetContentId, '100088');
    expect(plan?.season, 1);
    expect(plan?.episode, 3);
    expect(plan?.resumePosition, const Duration(minutes: 11));
    expect(plan?.isResumeEligible, isTrue);
    expect(plan?.reasonCode, ResumeReasonCode.applied);
  });

  test(
    'falls back to the first available episode when resume target is stale',
    () {
      final plan = useCase(
        seriesId: '100088',
        seasonSnapshots: <EpisodePlaybackSeasonSnapshot>[
          EpisodePlaybackSeasonSnapshot.fromEpisodeNumbers(
            seasonNumber: 1,
            episodeNumbers: const <int>[2, 3, 4],
          ),
          EpisodePlaybackSeasonSnapshot.fromEpisodeNumbers(
            seasonNumber: 2,
            episodeNumbers: const <int>[1, 2],
          ),
        ],
        resumeState: const PlaybackHistoryEntry(
          contentId: '100088',
          type: ContentType.series,
          title: 'The Last of Us',
          season: 3,
          episode: 9,
          lastPosition: Duration(minutes: 11),
          duration: Duration(minutes: 52),
        ),
      );

      expect(plan, isNotNull);
      expect(plan?.season, 1);
      expect(plan?.episode, 2);
      expect(plan?.resumePosition, isNull);
      expect(plan?.isResumeEligible, isFalse);
      expect(plan?.reasonCode, ResumeReasonCode.positionInvalid);
    },
  );
}
