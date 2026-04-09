import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/library/domain/repositories/continue_watching_repository.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class SeriesSeenMarker {
  const SeriesSeenMarker({
    required this.duration,
    required this.reasonCode,
    this.seasonNumber,
    this.episodeNumber,
  });

  final int? seasonNumber;
  final int? episodeNumber;
  final Duration duration;
  final String reasonCode;
}

SeriesSeenMarker resolveSeriesSeenMarker(
  List<Season> seasons, {
  DateTime? now,
  Duration fallbackDuration = const Duration(minutes: 45),
}) {
  final resolvedNow = now ?? DateTime.now();

  Episode? latestEpisode;
  int? latestSeasonNumber;

  for (final season in seasons) {
    for (final episode in season.episodes) {
      final airDate = episode.airDate;
      if (airDate != null && airDate.isAfter(resolvedNow)) {
        continue;
      }

      if (latestEpisode == null || latestSeasonNumber == null) {
        latestEpisode = episode;
        latestSeasonNumber = season.seasonNumber;
        continue;
      }

      final latestKey =
          latestSeasonNumber * 10000 + latestEpisode.episodeNumber;
      final candidateKey = season.seasonNumber * 10000 + episode.episodeNumber;
      if (candidateKey > latestKey) {
        latestEpisode = episode;
        latestSeasonNumber = season.seasonNumber;
      }
    }
  }

  if (latestEpisode == null || latestSeasonNumber == null) {
    return SeriesSeenMarker(
      duration: fallbackDuration,
      reasonCode: 'fallback_default_duration',
    );
  }

  final duration = latestEpisode.runtime ?? fallbackDuration;
  return SeriesSeenMarker(
    seasonNumber: latestSeasonNumber,
    episodeNumber: latestEpisode.episodeNumber,
    duration: duration,
    reasonCode: latestEpisode.runtime == null
        ? 'latest_released_episode_missing_runtime'
        : 'latest_released_episode',
  );
}

class MarkSeriesAsSeen {
  const MarkSeriesAsSeen(this._seenState, this._continueWatching, this._logger);

  final SeriesSeenStateRepository _seenState;
  final ContinueWatchingRepository _continueWatching;
  final AppLogger _logger;

  Future<void> call({
    required String seriesId,
    required String title,
    Uri? poster,
    List<Season> seasons = const <Season>[],
    String? userId,
    DateTime? playedAt,
    Duration fallbackEpisodeDuration = const Duration(minutes: 45),
  }) async {
    final marker = resolveSeriesSeenMarker(
      seasons,
      now: playedAt,
      fallbackDuration: fallbackEpisodeDuration,
    );

    _logger.debug(
      'series_mark_seen seriesId=$seriesId '
      'reasonCode=${marker.reasonCode} '
      'season=${marker.seasonNumber ?? 'n/a'} '
      'episode=${marker.episodeNumber ?? 'n/a'} '
      'durationMs=${marker.duration.inMilliseconds}',
      category: 'history',
    );

    final resolvedUserId = userId ?? 'default';
    await _seenState.markSeen(
      seriesId: seriesId,
      userId: resolvedUserId,
      seasonNumber: marker.seasonNumber,
      episodeNumber: marker.episodeNumber,
      markedAt: playedAt,
    );
    await _continueWatching.remove(seriesId, ContentType.series);
  }
}
