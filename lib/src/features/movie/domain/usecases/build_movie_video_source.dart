import 'package:movi/src/features/player/domain/entities/playback_launch_plan.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/movie/domain/services/movie_streaming_service.dart';
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
import 'package:movi/src/shared/domain/services/playback_resume_resolution.dart';

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
      final resume = resolvePlaybackResume(
        position: entry?.lastPosition,
        duration: entry?.duration,
      );
      final launchPlan = PlaybackLaunchPlan(
        contentType: ContentType.movie,
        targetContentId: movieId,
        resumePosition: resume.resumePosition,
        reasonCode: resume.reasonCode,
        isResumeEligible: resume.canResume,
      );
      return launchPlan.buildVideoSource(source: source);
    } catch (_) {
      return source;
    }
  }
}
