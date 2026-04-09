import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/presentation/providers/playback_history_providers.dart';

void main() {
  test(
    'mediaHistoryProvider matches shared resumable history filtering',
    () async {
      final getIt = GetIt.asNewInstance();
      final historyRepo = _FakeHistoryLocalRepository(
        entry: HistoryEntry(
          contentId: 'movie-1',
          type: ContentType.movie,
          title: 'Short Clip',
          lastPlayedAt: DateTime(2026),
          playCount: 1,
          lastPosition: Duration(seconds: 1),
          duration: Duration(seconds: 4),
          userId: 'user-a',
        ),
      );
      getIt.registerSingleton<HistoryLocalRepository>(historyRepo);

      final container = ProviderContainer(
        overrides: [
          slProvider.overrideWithValue(getIt),
          currentUserIdProvider.overrideWithValue('user-a'),
        ],
      );
      addTearDown(container.dispose);

      final entry = await container.read(
        hp.mediaHistoryProvider((
          contentId: 'movie-1',
          type: ContentType.movie,
        )).future,
      );
      final sharedEntry = await container.read(
        inProgressHistoryEntryProvider((
          contentId: 'movie-1',
          type: ContentType.movie,
        )).future,
      );

      expect(entry, isNull);
      expect(sharedEntry, isNull);
    },
  );

  test(
    'mediaHistoryProvider hides resumable series when a manual seen state exists',
    () async {
      final getIt = GetIt.asNewInstance();
      final historyEntry = HistoryEntry(
        contentId: 'series-1',
        type: ContentType.series,
        title: 'The Bear',
        lastPlayedAt: DateTime(2026),
        playCount: 1,
        lastPosition: const Duration(minutes: 10),
        duration: const Duration(minutes: 30),
        season: 1,
        episode: 2,
        userId: 'user-a',
      );
      getIt.registerSingleton<HistoryLocalRepository>(
        _FakeHistoryLocalRepository(entry: historyEntry),
      );
      getIt.registerSingleton<SeriesSeenStateRepository>(
        _FakeSeriesSeenStateRepository(
          state: SeriesSeenState(
            seriesId: 'series-1',
            userId: 'user-a',
            markedAt: DateTime(2026, 4, 9),
            seasonNumber: 1,
            episodeNumber: 3,
          ),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          slProvider.overrideWithValue(getIt),
          currentUserIdProvider.overrideWithValue('user-a'),
        ],
      );
      addTearDown(container.dispose);

      final entry = await container.read(
        hp.mediaHistoryProvider((
          contentId: 'series-1',
          type: ContentType.series,
        )).future,
      );

      expect(entry, isNull);
    },
  );
}

final class _FakeHistoryLocalRepository implements HistoryLocalRepository {
  const _FakeHistoryLocalRepository({this.entry});

  final HistoryEntry? entry;

  @override
  Future<HistoryEntry?> getSeriesResumeState(
    String seriesId, {
    String userId = 'default',
  }) async {
    return entry;
  }

  @override
  Future<HistoryEntry?> getEntry(
    String contentId,
    ContentType type, {
    int? season,
    int? episode,
    String userId = 'default',
  }) async {
    return entry;
  }

  @override
  Future<void> upsertPlay({
    required String contentId,
    required ContentType type,
    required String title,
    Uri? poster,
    DateTime? playedAt,
    Duration? position,
    Duration? duration,
    int? season,
    int? episode,
    String userId = 'default',
  }) async {}

  @override
  Future<void> remove(
    String contentId,
    ContentType type, {
    String userId = 'default',
  }) async {}

  @override
  Future<List<HistoryEntry>> readAll(
    ContentType type, {
    String userId = 'default',
  }) async {
    return entry == null ? const <HistoryEntry>[] : <HistoryEntry>[entry!];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Unexpected call: $invocation');
  }
}

final class _FakeSeriesSeenStateRepository
    implements SeriesSeenStateRepository {
  const _FakeSeriesSeenStateRepository({this.state});

  final SeriesSeenState? state;

  @override
  Future<void> clearSeen(String seriesId, {required String userId}) async {}

  @override
  Future<SeriesSeenState?> getSeenState(
    String seriesId, {
    required String userId,
  }) async {
    return state;
  }

  @override
  Future<void> markSeen({
    required String seriesId,
    required String userId,
    int? seasonNumber,
    int? episodeNumber,
    DateTime? markedAt,
  }) async {}
}
