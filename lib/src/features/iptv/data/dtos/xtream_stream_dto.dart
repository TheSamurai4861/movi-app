class XtreamStreamDto {
  XtreamStreamDto({
    required this.streamId,
    required this.name,
    required this.streamType,
    required this.categoryId,
    this.streamIcon,
    this.rating,
    this.rating5Based,
    this.plot,
    this.released,
    this.tmdbId,
  });

  factory XtreamStreamDto.fromJson(Map<String, dynamic> json) {
    dynamic tmdbRaw =
        json['tmdb'] ?? json['tmdb_id'] ?? json['tmdbId'] ?? json['tmdbID'];

    int? tmdbParsed;
    if (tmdbRaw is num) {
      tmdbParsed = tmdbRaw.toInt();
    } else if (tmdbRaw is String) {
      tmdbParsed = int.tryParse(tmdbRaw);
    }

    final released =
        (json['releasedate'] ?? json['releaseDate'] ?? json['release_date'])
            ?.toString();

    return XtreamStreamDto(
      streamId: json['stream_id'] is int
          ? json['stream_id'] as int
          : int.tryParse('${json['stream_id']}') ?? 0,
      name: json['name']?.toString() ?? 'Untitled',
      streamType: json['stream_type']?.toString() ?? 'vod',
      categoryId: json['category_id']?.toString() ?? '',
      streamIcon: (json['stream_icon'] ?? json['cover'])?.toString(),
      rating: double.tryParse('${json['rating']}'),
      rating5Based: double.tryParse('${json['rating_5based']}'),
      plot: json['plot']?.toString(),
      released: released,
      tmdbId: tmdbParsed,
    );
  }

  final int streamId;
  final String name;
  final String streamType;
  final String categoryId;
  final String? streamIcon;
  final double? rating;
  final double? rating5Based;
  final String? plot;
  final String? released;
  final int? tmdbId;
}
