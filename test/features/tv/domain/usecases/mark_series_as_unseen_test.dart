import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/library/domain/repositories/continue_watching_repository.dart';
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
import 'package:movi/src/features/tv/domain/usecases/mark_series_as_unseen.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

void main() {
  test(
    'MarkSeriesAsUnseen clears playback history and continue watching',
    () async {
      final history = _FakePlaybackHistoryRepository();
      final continueWatching = _FakeContinueWatchingRepository();
      final seenState = _FakeSeriesSeenStateRepository();
      final useCase = MarkSeriesAsUnseen(history, continueWatching, seenState);

      await useCase('series-1', userId: 'user-a');

      expect(history.removedContentId, 'series-1');
      expect(history.removedType, ContentType.series);
      expect(history.removedUserId, 'user-a');
      expect(seenState.clearedSeriesId, 'series-1');
      expect(seenState.clearedUserId, 'user-a');
      expect(continueWatching.removedContentId, 'series-1');
      expect(continueWatching.removedType, ContentType.series);
    },
  );
}

class _FakePlaybackHistoryRepository implements PlaybackHistoryRepository {
  String? removedContentId;
  ContentType? removedType;
  String? removedUserId;

  @override
  Future<void> remove(
    String contentId,
    ContentType type, {
    String? userId,
  }) async {
    removedContentId = contentId;
    removedType = type;
    removedUserId = userId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Unexpected call: $invocation');
  }
}

class _FakeSeriesSeenStateRepository implements SeriesSeenStateRepository {
  String? clearedSeriesId;
  String? clearedUserId;

  @override
  Future<void> clearSeen(String seriesId, {required String userId}) async {
    clearedSeriesId = seriesId;
    clearedUserId = userId;
  }

  @override
  Future<SeriesSeenState?> getSeenState(
    String seriesId, {
    required String userId,
  }) async => null;

  @override
  Future<void> markSeen({
    required String seriesId,
    required String userId,
    int? seasonNumber,
    int? episodeNumber,
    DateTime? markedAt,
  }) async {}
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
