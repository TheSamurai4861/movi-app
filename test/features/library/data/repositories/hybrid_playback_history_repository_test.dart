import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/storage/repositories/history_local_repository.dart';
import 'package:movi/src/features/library/data/repositories/hybrid_playback_history_repository.dart';
import 'package:movi/src/features/library/data/repositories/supabase_playback_history_repository.dart';
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

void main() {
  test('upsertPlay remains successful when remote sync fails', () async {
    final local = _RecordingLocalHistoryRepository();
    final remote = _FailingSupabasePlaybackHistoryRepository();
    final repository = HybridPlaybackHistoryRepository(
      local: local,
      defaultUserId: 'user-local',
      remote: remote,
    );

    await repository.upsertPlay(
      contentId: '603',
      type: ContentType.movie,
      title: 'The Matrix',
      position: const Duration(minutes: 40),
      duration: const Duration(minutes: 120),
    );
    await Future<void>.delayed(Duration.zero);

    expect(local.upsertCount, 1);
    expect(local.lastUserId, 'user-local');
    expect(remote.upsertCount, 1);
  });

  test('getSeriesResumeState reads the canonical local series state', () async {
    final local = _RecordingLocalHistoryRepository();
    final repository = HybridPlaybackHistoryRepository(
      local: local,
      defaultUserId: 'user-local',
      remote: null,
    );

    await repository.getSeriesResumeState('series-1');

    expect(local.lastSeriesResumeStateId, 'series-1');
    expect(local.lastUserId, 'user-local');
  });
}

class _RecordingLocalHistoryRepository implements HistoryLocalRepository {
  int upsertCount = 0;
  String? lastUserId;
  String? lastSeriesResumeStateId;

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
  }) async {
    upsertCount += 1;
    lastUserId = userId;
  }

  @override
  Future<HistoryEntry?> getSeriesResumeState(
    String seriesId, {
    String userId = 'default',
  }) async {
    lastSeriesResumeStateId = seriesId;
    lastUserId = userId;
    return null;
  }

  @override
  Future<HistoryEntry?> getEntry(
    String contentId,
    ContentType type, {
    int? season,
    int? episode,
    String userId = 'default',
  }) async {
    return null;
  }

  @override
  Future<List<HistoryEntry>> readAll(
    ContentType type, {
    String userId = 'default',
  }) async {
    return const <HistoryEntry>[];
  }

  @override
  Future<void> remove(
    String contentId,
    ContentType type, {
    String userId = 'default',
  }) async {}
}

class _FailingSupabasePlaybackHistoryRepository
    implements SupabasePlaybackHistoryRepository {
  int upsertCount = 0;

  @override
  String get profileId => 'profile-id';

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
    String? userId,
  }) async {
    upsertCount += 1;
    throw StateError('remote error');
  }

  @override
  Future<PlaybackHistoryEntry?> getSeriesResumeState(
    String seriesId, {
    String? userId,
  }) async {
    return null;
  }

  @override
  Future<PlaybackHistoryEntry?> getEntry(
    String contentId,
    ContentType type, {
    int? season,
    int? episode,
    String? userId,
  }) async {
    return null;
  }

  @override
  Future<void> remove(
    String contentId,
    ContentType type, {
    String? userId,
  }) async {}
}
