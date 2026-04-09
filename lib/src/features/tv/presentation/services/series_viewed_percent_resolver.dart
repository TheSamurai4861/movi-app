import 'package:movi/src/features/tv/presentation/models/tv_detail_view_model.dart';
import 'package:movi/src/shared/domain/constants/playback_progress_thresholds.dart';

double? resolveSeriesViewedPercent({
  required List<SeasonViewModel> seasons,
  required int? seasonNumber,
  required int? episodeNumber,
  required Duration? position,
  required Duration? duration,
  bool isMarkedSeen = false,
}) {
  final totalEpisodeCount = _countTrackableEpisodes(seasons);
  if (totalEpisodeCount == 0) return null;

  if (seasonNumber != null && episodeNumber != null) {
    final ordinal = _findEpisodeOrdinal(
      seasons,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
    if (ordinal != null) {
      return ordinal / totalEpisodeCount;
    }
  }

  if (duration == null || duration.inSeconds <= 0) {
    return isMarkedSeen ? 1.0 : null;
  }

  final progress = (position?.inSeconds ?? 0) / duration.inSeconds;
  if (progress >= PlaybackProgressThresholds.maxInProgress) {
    return 1.0;
  }

  return isMarkedSeen ? 1.0 : null;
}

int _countTrackableEpisodes(List<SeasonViewModel> seasons) {
  var count = 0;
  final sortedSeasons = List<SeasonViewModel>.from(seasons)
    ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));
  for (final season in sortedSeasons) {
    if (season.seasonNumber <= 0) continue;
    count += season.episodes.length;
  }
  return count;
}

int? _findEpisodeOrdinal(
  List<SeasonViewModel> seasons, {
  required int seasonNumber,
  required int episodeNumber,
}) {
  var ordinal = 0;
  final sortedSeasons = List<SeasonViewModel>.from(seasons)
    ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));

  for (final season in sortedSeasons) {
    if (season.seasonNumber <= 0) continue;

    final sortedEpisodes = List<EpisodeViewModel>.from(season.episodes)
      ..sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
    for (final episode in sortedEpisodes) {
      ordinal++;
      if (season.seasonNumber == seasonNumber &&
          episode.episodeNumber == episodeNumber) {
        return ordinal;
      }
    }
  }

  return null;
}
