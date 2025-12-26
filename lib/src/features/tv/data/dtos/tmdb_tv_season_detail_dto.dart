class TmdbTvSeasonDetailDto {
  TmdbTvSeasonDetailDto({
    required this.id,
    required this.name,
    required this.airDate,
    required this.episodes,
  });

  factory TmdbTvSeasonDetailDto.fromJson(Map<String, dynamic> json) {
    return TmdbTvSeasonDetailDto(
      id: json['id'] as int,
      name: json['name']?.toString() ?? 'Season',
      airDate: json['air_date']?.toString(),
      episodes: (json['episodes'] as List<dynamic>? ?? const [])
          .map(
            (episode) =>
                TmdbTvEpisodeDto.fromJson(episode as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final int id;
  final String name;
  final String? airDate;
  final List<TmdbTvEpisodeDto> episodes;

  Map<String, dynamic> toCache() => {
    'id': id,
    'name': name,
    'air_date': airDate,
    'episodes': episodes.map((episode) => episode.toJson()).toList(),
  };

  factory TmdbTvSeasonDetailDto.fromCache(Map<String, dynamic> json) =>
      TmdbTvSeasonDetailDto.fromJson(json);
}

class TmdbTvEpisodeDto {
  TmdbTvEpisodeDto({
    required this.id,
    required this.name,
    required this.airDate,
    required this.voteAverage,
    required this.runtime,
    required this.stillPath,
    required this.overview,
    required this.episodeNumber,
  });

  factory TmdbTvEpisodeDto.fromJson(Map<String, dynamic> json) {
    return TmdbTvEpisodeDto(
      id: json['id'] as int,
      name: json['name']?.toString() ?? 'Episode',
      airDate: json['air_date']?.toString(),
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      runtime: json['runtime'] as int?,
      stillPath: json['still_path']?.toString(),
      overview: json['overview']?.toString() ?? '',
      episodeNumber: json['episode_number'] as int? ?? 0,
    );
  }

  final int id;
  final String name;
  final String? airDate;
  final double? voteAverage;
  final int? runtime;
  final String? stillPath;
  final String overview;
  final int episodeNumber;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'air_date': airDate,
    'vote_average': voteAverage,
    'runtime': runtime,
    'still_path': stillPath,
    'overview': overview,
    'episode_number': episodeNumber,
  };
}
