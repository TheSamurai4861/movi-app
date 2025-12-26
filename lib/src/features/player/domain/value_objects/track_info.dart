enum TrackType { audio, subtitle }

class TrackInfo {
  const TrackInfo({
    required this.type,
    required this.id,
    this.title,
    this.language,
  });

  final TrackType type;
  final int id;
  final String? title;
  final String? language;
}
