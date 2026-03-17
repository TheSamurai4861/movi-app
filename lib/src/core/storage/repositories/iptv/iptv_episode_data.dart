/// Cached IPTV episode identifier along with its optional container extension.
///
/// This value object is reused by TV enrichment and stream URL resolution when
/// a series episode can be resolved from local storage.
class EpisodeData {
  const EpisodeData({required this.episodeId, this.extension});

  final int episodeId;
  final String? extension;
}
