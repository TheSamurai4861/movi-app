import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/library/domain/repositories/continue_watching_repository.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/features/tv/domain/usecases/mark_series_as_seen.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

void main() {
  test('resolveSeriesSeenMarker targets the latest released episode', () {
    final marker = resolveSeriesSeenMarker(<Season>[
      Season(
        id: const SeasonId('season-1'),
        seasonNumber: 1,
        title: MediaTitle('Season 1'),
        episodes: <Episode>[
          Episode(
            id: const EpisodeId('s1e1'),
            episodeNumber: 1,
            title: MediaTitle('Pilot'),
            runtime: const Duration(minutes: 41),
            airDate: DateTime(2024, 1, 1),
          ),
        ],
      ),
      Season(
        id: const SeasonId('season-2'),
        seasonNumber: 2,
        title: MediaTitle('Season 2'),
        episodes: <Episode>[
          Episode(
            id: const EpisodeId('s2e1'),
            episodeNumber: 1,
            title: MediaTitle('Premiere'),
            runtime: const Duration(minutes: 52),
            airDate: DateTime(2027, 1, 1),
          ),
          Episode(
            id: const EpisodeId('s2e0'),
            episodeNumber: 0,
            title: MediaTitle('Special'),
            runtime: const Duration(minutes: 48),
            airDate: DateTime(2025, 1, 1),
          ),
        ],
      ),
    ], now: DateTime(2026, 4, 9));

    expect(marker.seasonNumber, 2);
    expect(marker.episodeNumber, 0);
    expect(marker.duration, const Duration(minutes: 48));
    expect(marker.reasonCode, 'latest_released_episode');
  });

  test('resolveSeriesSeenMarker falls back when nothing is released yet', () {
    final marker = resolveSeriesSeenMarker(<Season>[
      Season(
        id: const SeasonId('season-1'),
        seasonNumber: 1,
        title: MediaTitle('Season 1'),
        episodes: <Episode>[
          Episode(
            id: const EpisodeId('s1e1'),
            episodeNumber: 1,
            title: MediaTitle('Pilot'),
            airDate: DateTime(2027, 1, 1),
          ),
        ],
      ),
    ], now: DateTime(2026, 4, 9));

    expect(marker.seasonNumber, isNull);
    expect(marker.episodeNumber, isNull);
    expect(marker.duration, const Duration(minutes: 45));
    expect(marker.reasonCode, 'fallback_default_duration');
  });

  test(
    'MarkSeriesAsSeen stores a manual seen state and clears continue watching',
    () async {
      final seenState = _FakeSeriesSeenStateRepository();
      final continueWatching = _FakeContinueWatchingRepository();
      final useCase = MarkSeriesAsSeen(
        seenState,
        continueWatching,
        _MemoryLogger(),
      );

      await useCase(
        seriesId: 'series-1',
        title: 'The Bear',
        seasons: <Season>[
          Season(
            id: const SeasonId('season-1'),
            seasonNumber: 1,
            title: MediaTitle('Season 1'),
            episodes: <Episode>[
              Episode(
                id: const EpisodeId('s1e1'),
                episodeNumber: 1,
                title: MediaTitle('System'),
                runtime: const Duration(minutes: 29),
                airDate: DateTime(2024, 1, 1),
              ),
            ],
          ),
        ],
        userId: 'user-a',
        playedAt: DateTime(2026, 4, 9),
      );

      expect(seenState.markedSeriesId, 'series-1');
      expect(seenState.markedSeasonNumber, 1);
      expect(seenState.markedEpisodeNumber, 1);
      expect(seenState.markedUserId, 'user-a');
      expect(seenState.markedAt, DateTime(2026, 4, 9));
      expect(continueWatching.removedContentId, 'series-1');
      expect(continueWatching.removedType, ContentType.series);
    },
  );
}

class _FakeSeriesSeenStateRepository implements SeriesSeenStateRepository {
  String? markedSeriesId;
  int? markedSeasonNumber;
  int? markedEpisodeNumber;
  String? markedUserId;
  DateTime? markedAt;

  @override
  Future<void> markSeen({
    required String seriesId,
    required String userId,
    int? seasonNumber,
    int? episodeNumber,
    DateTime? markedAt,
  }) async {
    markedSeriesId = seriesId;
    markedSeasonNumber = seasonNumber;
    markedEpisodeNumber = episodeNumber;
    markedUserId = userId;
    this.markedAt = markedAt;
  }

  @override
  Future<void> clearSeen(String seriesId, {required String userId}) async {}

  @override
  Future<SeriesSeenState?> getSeenState(
    String seriesId, {
    required String userId,
  }) async => null;
}

class _FakeContinueWatchingRepository implements ContinueWatchingRepository {
  String? removedContentId;
  ContentType? removedType;

  @override
  Future<void> remove(String contentId, ContentType type) async {
    removedContentId = contentId;
    removedType = type;
  }
}

class _MemoryLogger implements AppLogger {
  @override
  void debug(String message, {String? category}) {}

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void info(String message, {String? category}) {}

  @override
  void log(
    LogLevel level,
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {}

  @override
  void warn(String message, {String? category}) {}
}
