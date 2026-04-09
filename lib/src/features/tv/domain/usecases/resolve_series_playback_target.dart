import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
import 'package:movi/src/features/player/domain/entities/playback_launch_plan.dart';
import 'package:movi/src/features/tv/domain/entities/episode_playback_season_snapshot.dart';
import 'package:movi/src/shared/domain/services/media_resume_decision.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class ResolveSeriesPlaybackTarget {
  const ResolveSeriesPlaybackTarget();

  PlaybackLaunchPlan? call({
    required String seriesId,
    required List<EpisodePlaybackSeasonSnapshot> seasonSnapshots,
    PlaybackHistoryEntry? resumeState,
  }) {
    final sortedSnapshots = seasonSnapshots.toList(growable: true)
      ..sort((left, right) => left.seasonNumber.compareTo(right.seasonNumber));

    final firstTarget = _firstAvailableTarget(sortedSnapshots);
    if (firstTarget == null) {
      return null;
    }

    final resumeSeason = resumeState?.season;
    final resumeEpisode = resumeState?.episode;
    if (resumeSeason != null &&
        resumeEpisode != null &&
        _containsEpisode(
          snapshots: sortedSnapshots,
          seasonNumber: resumeSeason,
          episodeNumber: resumeEpisode,
        )) {
      return PlaybackLaunchPlan.fromPlaybackProgress(
        contentType: ContentType.series,
        targetContentId: seriesId,
        season: resumeSeason,
        episode: resumeEpisode,
        position: resumeState?.lastPosition,
        duration: resumeState?.duration,
      );
    }

    return PlaybackLaunchPlan(
      contentType: ContentType.series,
      targetContentId: seriesId,
      season: firstTarget.$1,
      episode: firstTarget.$2,
      resumePosition: null,
      reasonCode: resumeState == null
          ? ResumeReasonCode.noPosition
          : ResumeReasonCode.positionInvalid,
      isResumeEligible: false,
    );
  }

  (int, int)? _firstAvailableTarget(
    List<EpisodePlaybackSeasonSnapshot> snapshots,
  ) {
    for (final season in snapshots) {
      final firstEpisodeNumber = season.firstEpisodeNumber;
      if (season.episodeCount > 0 && firstEpisodeNumber != null) {
        return (season.seasonNumber, firstEpisodeNumber);
      }
    }
    return null;
  }

  bool _containsEpisode({
    required List<EpisodePlaybackSeasonSnapshot> snapshots,
    required int seasonNumber,
    required int episodeNumber,
  }) {
    for (final season in snapshots) {
      if (season.seasonNumber != seasonNumber) {
        continue;
      }
      final firstEpisodeNumber = season.firstEpisodeNumber;
      final lastEpisodeNumber = season.lastEpisodeNumber;
      if (firstEpisodeNumber == null || lastEpisodeNumber == null) {
        return false;
      }
      return episodeNumber >= firstEpisodeNumber &&
          episodeNumber <= lastEpisodeNumber;
    }
    return false;
  }
}
