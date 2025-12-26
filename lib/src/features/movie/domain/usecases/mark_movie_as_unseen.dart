import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
import 'package:movi/src/features/library/domain/repositories/continue_watching_repository.dart';

class MarkMovieAsUnseen {
  const MarkMovieAsUnseen(this._history, this._continueWatching);
  final PlaybackHistoryRepository _history;
  final ContinueWatchingRepository _continueWatching;

  Future<void> call(String movieId, {String? userId}) async {
    await _history.remove(movieId, ContentType.movie, userId: userId);
    await _continueWatching.remove(movieId, ContentType.movie);
  }
}
