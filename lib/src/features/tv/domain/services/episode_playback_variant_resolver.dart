import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
import 'package:movi/src/features/tv/domain/entities/episode_playback_season_snapshot.dart';

abstract class EpisodePlaybackVariantResolver {
  Future<List<PlaybackVariant>> resolveVariants({
    required String seriesId,
    required int seasonNumber,
    required int episodeNumber,
    required List<EpisodePlaybackSeasonSnapshot> seasonSnapshots,
    Set<String>? candidateSourceIds,
  });
}
