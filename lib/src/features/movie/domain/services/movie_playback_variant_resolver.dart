import 'package:movi/src/features/player/domain/entities/playback_variant.dart';

abstract class MoviePlaybackVariantResolver {
  Future<List<PlaybackVariant>> resolveVariants({
    required String movieId,
    required String title,
    int? releaseYear,
    Uri? poster,
    Set<String>? candidateSourceIds,
  });
}
