import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/library/domain/repositories/continue_watching_repository.dart';
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class MarkSeriesAsUnseen {
  const MarkSeriesAsUnseen(
    this._history,
    this._continueWatching,
    this._seenState,
  );

  final PlaybackHistoryRepository _history;
  final ContinueWatchingRepository _continueWatching;
  final SeriesSeenStateRepository _seenState;

  Future<void> call(String seriesId, {String? userId}) async {
    final resolvedUserId = userId ?? 'default';
    await _history.remove(seriesId, ContentType.series, userId: resolvedUserId);
    await _seenState.clearSeen(seriesId, userId: resolvedUserId);
    await _continueWatching.remove(seriesId, ContentType.series);
  }
}
