class TmdbTvDetailDto {
  TmdbTvDetailDto({
    required this.id,
    required this.name,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.logoPath,
    required this.firstAirDate,
    required this.lastAirDate,
    required this.status,
    required this.voteAverage,
    required this.genres,
    required this.cast,
    required this.creators,
    required this.seasons,
    required this.recommendations,
    required this.isFullPayload,
  });

  factory TmdbTvDetailDto.fromJson(Map<String, dynamic> json) {
    // Détermine si le payload est "full" (append_to_response: images/credits/recommendations)
    final bool isFull =
        json.containsKey('images') ||
        json.containsKey('credits') ||
        json.containsKey('recommendations');
    final images = json['images'] as Map<String, dynamic>?;
    final logos = images?['logos'] as List<dynamic>? ?? const [];
    final logoPath = _selectLogo(logos);
    final credits = json['credits'] as Map<String, dynamic>?;
    final cast = (credits?['cast'] as List<dynamic>? ?? const [])
        .map((item) => TmdbTvCastDto.fromJson(item as Map<String, dynamic>))
        .toList();
    final crew = (credits?['crew'] as List<dynamic>? ?? const [])
        .map((item) => TmdbTvCrewDto.fromJson(item as Map<String, dynamic>))
        .toList();
    final recommendations =
        ((json['recommendations'] as Map<String, dynamic>?)?['results']
                    as List<dynamic>? ??
                const [])
            .map(
              (item) => TmdbTvSummaryDto.fromJson(item as Map<String, dynamic>),
            )
            .toList();
    final createdBy = (json['created_by'] as List<dynamic>? ?? const [])
        .map((c) => TmdbTvCrewDto.fromJson(c as Map<String, dynamic>))
        .toList();
    final creators = createdBy.isNotEmpty
        ? createdBy
        : crew
              .where((member) => member.job?.toLowerCase() == 'creator')
              .toList();

    return TmdbTvDetailDto(
      id: json['id'] as int,
      name:
          json['name']?.toString() ??
          json['original_name']?.toString() ??
          'Untitled',
      overview: json['overview']?.toString() ?? '',
      posterPath: json['poster_path']?.toString(),
      backdropPath: json['backdrop_path']?.toString(),
      logoPath: logoPath,
      firstAirDate: json['first_air_date']?.toString(),
      lastAirDate: json['last_air_date']?.toString(),
      status: json['status']?.toString(),
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      genres: (json['genres'] as List<dynamic>? ?? const [])
          .map((g) => g['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList(),
      cast: cast,
      creators: creators,
      seasons: (json['seasons'] as List<dynamic>? ?? const [])
          .map(
            (season) =>
                TmdbTvSeasonDto.fromJson(season as Map<String, dynamic>),
          )
          .toList(),
      recommendations: recommendations,
      isFullPayload: isFull,
    );
  }

  final int id;
  final String name;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final String? logoPath;
  final String? firstAirDate;
  final String? lastAirDate;
  final String? status;
  final double? voteAverage;
  final List<String> genres;
  final List<TmdbTvCastDto> cast;
  final List<TmdbTvCrewDto> creators;
  final List<TmdbTvSeasonDto> seasons;
  final List<TmdbTvSummaryDto> recommendations;
  final bool isFullPayload;

  Map<String, dynamic> toCache() => {
    'id': id,
    'name': name,
    'overview': overview,
    'poster_path': posterPath,
    'backdrop_path': backdropPath,
    'images': {
      'logos': logoPath != null
          ? [
              {
                'file_path': logoPath,
                'vote_average': voteAverage,
                'iso_639_1': null,
              },
            ]
          : [],
    },
    'first_air_date': firstAirDate,
    'last_air_date': lastAirDate,
    'status': status,
    'vote_average': voteAverage,
    'genres': genres.map((g) => {'name': g}).toList(),
    'credits': {
      'cast': cast.map((c) => c.toJson()).toList(),
      'crew': creators.map((c) => c.toJson()).toList(),
    },
    'created_by': creators.map((c) => c.toJson()).toList(),
    'seasons': seasons.map((season) => season.toJson()).toList(),
    'recommendations': {
      'results': recommendations.map((r) => r.toJson()).toList(),
    },
  };

  factory TmdbTvDetailDto.fromCache(Map<String, dynamic> json) =>
      TmdbTvDetailDto.fromJson(json);
}

String? _selectLogo(List<dynamic> logos) {
  if (logos.isEmpty) return null;
  logos.sort(
    (a, b) =>
        ((b['vote_average'] as num?)?.compareTo(
          (a['vote_average'] as num?) ?? 0,
        ) ??
        0),
  );
  final best = logos.cast<Map<String, dynamic>>().firstWhere(
    (logo) => (logo['iso_639_1']?.toString().isNotEmpty ?? false),
    orElse: () => logos.first as Map<String, dynamic>,
  );
  return best['file_path']?.toString();
}

class TmdbTvCastDto {
  TmdbTvCastDto({
    required this.id,
    required this.name,
    required this.character,
    required this.profilePath,
  });

  factory TmdbTvCastDto.fromJson(Map<String, dynamic> json) {
    return TmdbTvCastDto(
      id: json['id'] as int,
      name: json['name']?.toString() ?? 'Unknown',
      character: json['character']?.toString(),
      profilePath: json['profile_path']?.toString(),
    );
  }

  final int id;
  final String name;
  final String? character;
  final String? profilePath;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'character': character,
    'profile_path': profilePath,
  };
}

class TmdbTvCrewDto {
  TmdbTvCrewDto({required this.id, required this.name, required this.job});

  factory TmdbTvCrewDto.fromJson(Map<String, dynamic> json) {
    return TmdbTvCrewDto(
      id: json['id'] as int,
      name: json['name']?.toString() ?? 'Unknown',
      job: json['job']?.toString(),
    );
  }

  final int id;
  final String name;
  final String? job;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'job': job};
}

class TmdbTvSeasonDto {
  TmdbTvSeasonDto({
    required this.id,
    required this.name,
    required this.overview,
    required this.posterPath,
    required this.airDate,
    required this.seasonNumber,
    required this.episodeCount,
  });

  factory TmdbTvSeasonDto.fromJson(Map<String, dynamic> json) {
    return TmdbTvSeasonDto(
      id: json['id'] as int,
      name: json['name']?.toString() ?? 'Season',
      overview: json['overview']?.toString() ?? '',
      posterPath: json['poster_path']?.toString(),
      airDate: json['air_date']?.toString(),
      seasonNumber: json['season_number'] as int? ?? 0,
      episodeCount: json['episode_count'] as int? ?? 0,
    );
  }

  final int id;
  final String name;
  final String overview;
  final String? posterPath;
  final String? airDate;
  final int seasonNumber;
  final int episodeCount;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'overview': overview,
    'poster_path': posterPath,
    'air_date': airDate,
    'season_number': seasonNumber,
    'episode_count': episodeCount,
  };
}

class TmdbTvSummaryDto {
  TmdbTvSummaryDto({
    required this.id,
    required this.name,
    required this.posterPath,
    required this.backdropPath,
    required this.firstAirDate,
    required this.voteAverage,
  });

  factory TmdbTvSummaryDto.fromJson(Map<String, dynamic> json) {
    return TmdbTvSummaryDto(
      id: json['id'] as int,
      name:
          json['name']?.toString() ??
          json['original_name']?.toString() ??
          'Untitled',
      posterPath: json['poster_path']?.toString(),
      backdropPath: json['backdrop_path']?.toString(),
      firstAirDate: json['first_air_date']?.toString(),
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
    );
  }

  final int id;
  final String name;
  final String? posterPath;
  final String? backdropPath;
  final String? firstAirDate;
  final double? voteAverage;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'poster_path': posterPath,
    'backdrop_path': backdropPath,
    'first_air_date': firstAirDate,
    'vote_average': voteAverage,
  };
}
