import 'package:movi/src/features/player/domain/entities/video_source.dart';

abstract class MovieStreamingService {
  Future<VideoSource?> buildMovieSource({
    required String movieId,
    required String title,
    Uri? poster,
    Set<String>? preferredAccountIds,
  });
}
