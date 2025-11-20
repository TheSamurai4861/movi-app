import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';

class MarkMovieAsSeen {
  const MarkMovieAsSeen(this._history);
  final PlaybackHistoryRepository _history;

  Future<void> call({
    required String movieId,
    required String title,
    Uri? poster,
    Duration? duration,
  }) async {
    final d = duration ?? const Duration(hours: 2);
    await _history.upsertPlay(
      contentId: movieId,
      type: ContentType.movie,
      title: title,
      poster: poster,
      position: d,
      duration: d,
    );
  }
}
