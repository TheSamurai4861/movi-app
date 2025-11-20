import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';

abstract class XtreamStreamUrlBuilder {
  Future<String?> buildMovieStreamUrl({
    required int streamId,
    required String accountId,
  });

  Future<String?> buildEpisodeStreamUrl({
    required int episodeId,
    required String accountId,
    String? extension,
    int? seriesId,
  });

  Future<String?> buildStreamUrlFromMovieItem(XtreamPlaylistItem item);

  Future<String?> buildStreamUrlFromSeriesItem({
    required XtreamPlaylistItem item,
    required int seasonNumber,
    required int episodeNumber,
  });
}
