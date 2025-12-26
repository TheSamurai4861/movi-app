class XtreamStreamDto {
  XtreamStreamDto({
    required this.streamId,
    required this.name,
    required this.streamType,
    required this.categoryId,
    this.streamIcon,
    this.containerExtension,
    this.rating,
    this.rating5Based,
    this.plot,
    this.released,
    this.year,
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
        (json['releasedate'] ??
                json['releaseDate'] ??
                json['release_date'] ??
                json['released'])
            ?.toString();

    final yearRaw = json['year'];
    int? yearParsed;
    if (yearRaw is num) {
      yearParsed = yearRaw.toInt();
    } else if (yearRaw is String) {
      yearParsed = int.tryParse(yearRaw.trim());
    }

    // Essayer plusieurs noms de champs possibles pour stream_id
    // Certaines APIs Xtream utilisent 'id' au lieu de 'stream_id' pour les séries
    dynamic streamIdRaw =
        json['stream_id'] ??
        json['id'] ??
        json['series_id'] ??
        json['seriesId'];

    int streamId;
    if (streamIdRaw is int) {
      streamId = streamIdRaw;
    } else if (streamIdRaw is num) {
      streamId = streamIdRaw.toInt();
    } else if (streamIdRaw is String) {
      streamId = int.tryParse(streamIdRaw) ?? 0;
    } else {
      streamId = 0;
    }

    return XtreamStreamDto(
      streamId: streamId,
      name:
          json['name']?.toString() ??
          json['title']?.toString() ??
          json['series_name']?.toString() ??
          'Untitled',
      streamType: json['stream_type']?.toString() ?? 'vod',
      categoryId: json['category_id']?.toString() ?? '',
      streamIcon: (json['stream_icon'] ?? json['cover'])?.toString(),
      containerExtension:
          (json['container_extension'] ??
                  json['containerExtension'] ??
                  json['extension'])
              ?.toString(),
      rating: double.tryParse('${json['rating']}'),
      rating5Based: double.tryParse('${json['rating_5based']}'),
      plot: json['plot']?.toString(),
      released: released,
      year: yearParsed,
      tmdbId: tmdbParsed,
    );
  }

  final int streamId;
  final String name;
  final String streamType;
  final String categoryId;
  final String? streamIcon;
  final String? containerExtension;
  final double? rating;
  final double? rating5Based;
  final String? plot;
  final String? released;
  final int? year;
  final int? tmdbId;
}
