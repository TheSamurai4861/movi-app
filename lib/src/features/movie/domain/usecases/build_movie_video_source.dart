import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/movie/domain/services/movie_streaming_service.dart';
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';

class BuildMovieVideoSource {
  const BuildMovieVideoSource(this._streaming, this._history);

  final MovieStreamingService _streaming;
  final PlaybackHistoryRepository _history;

  Future<VideoSource?> call({
    required String movieId,
    required String title,
    Uri? poster,
    String? userId,
    Set<String>? activeSourceIds,
  }) async {
    final source = await _streaming.buildMovieSource(
      movieId: movieId,
      title: title,
      poster: poster,
      preferredAccountIds: activeSourceIds,
    );
    if (source == null) return null;

    try {
      final entry = await _history.getEntry(
        movieId,
        ContentType.movie,
        userId: userId,
      );
      final resume = entry?.lastPosition;
      return VideoSource(
        url: source.url,
        title: source.title,
        contentId: source.contentId,
        tmdbId: source.tmdbId,
        contentType: source.contentType,
        poster: source.poster,
        resumePosition: resume,
      );
    } catch (_) {
      return source;
    }
  }
}
