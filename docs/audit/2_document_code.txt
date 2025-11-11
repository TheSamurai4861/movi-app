class TmdbMovieDetailDto {
  TmdbMovieDetailDto({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.logoPath,
    required this.releaseDate,
    required this.runtime,
    required this.voteAverage,
    required this.genres,
    required this.cast,
    required this.directors,
    required this.recommendations,
    this.belongsToCollection,
  });

  factory TmdbMovieDetailDto.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as Map<String, dynamic>?;
    final logos = images?['logos'] as List<dynamic>? ?? const [];
    final logoPath = _selectLogo(logos);
    final credits = json['credits'] as Map<String, dynamic>?;
    final cast = (credits?['cast'] as List<dynamic>? ?? const [])
        .map((item) => TmdbMovieCastDto.fromJson(item as Map<String, dynamic>))
        .toList();
    final crew = (credits?['crew'] as List<dynamic>? ?? const [])
        .map((item) => TmdbMovieCrewDto.fromJson(item as Map<String, dynamic>))
        .toList();
    final recommendations =
        ((json['recommendations'] as Map<String, dynamic>?)?['results']
                    as List<dynamic>? ??
                const [])
            .map(
              (item) =>
                  TmdbMovieSummaryDto.fromJson(item as Map<String, dynamic>),
            )
            .toList();

    return TmdbMovieDetailDto(
      id: json['id'] as int,
      title:
          json['title']?.toString() ??
          json['original_title']?.toString() ??
          'Untitled',
      overview: json['overview']?.toString() ?? '',
      posterPath: json['poster_path']?.toString(),
      backdropPath: json['backdrop_path']?.toString(),
      logoPath: logoPath,
      releaseDate: json['release_date']?.toString(),
      runtime: json['runtime'] as int?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      genres: (json['genres'] as List<dynamic>? ?? const [])
          .map((g) => g['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList(),
      cast: cast,
      directors: crew
          .where((member) => member.job?.toLowerCase() == 'director')
          .toList(),
      recommendations: recommendations,
      belongsToCollection: json['belongs_to_collection'] is Map<String, dynamic>
          ? TmdbCollectionRefDto.fromJson(
              json['belongs_to_collection'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final String? logoPath;
  final String? releaseDate;
  final int? runtime;
  final double? voteAverage;
  final List<String> genres;
  final List<TmdbMovieCastDto> cast;
  final List<TmdbMovieCrewDto> directors;
  final List<TmdbMovieSummaryDto> recommendations;
  final TmdbCollectionRefDto? belongsToCollection;

  Map<String, dynamic> toCache() {
  // On réutilise les champs déjà parsés + on propage les posters/logos
  return {
    'id': id,
    'title': title,
    'overview': overview,
    'poster_path': posterPath,
    'backdrop_path': backdropPath,
    'release_date': releaseDate,
    'runtime': runtime,
    'vote_average': voteAverage,
    'genres': genres.map((name) => {'name': name}).toList(),
    'credits': {
      'cast': cast.map((c) => c.toJson()).toList(),
      'crew': directors.map((d) => d.toJson()).toList(),
    },
    'recommendations': {
      'results': recommendations.map((r) => r.toJson()).toList(),
    },
    if (belongsToCollection != null)
      'belongs_to_collection': belongsToCollection!.toJson(),
    // IMPORTANT : inclure images.logos + images.posters
    'images': {
      'logos': logoPath != null
          ? [
              {
                'file_path': logoPath,
                'vote_average': voteAverage,
                'iso_639_1': 'fr', // ou null, on ne force rien en pratique (non bloquant)
              }
            ]
          : [],
      // on ne les a pas tous ici, mais si l’API a renvoyé images dans fromJson,
      // tu peux opter pour une copie “brute” si tu la conserves ailleurs.
      // Ici on reste minimaliste : le fallback utilisera poster_path si pas de posters listés en cache.
      'posters': [],
    },
  };
}

  factory TmdbMovieDetailDto.fromCache(Map<String, dynamic> json) {
    return TmdbMovieDetailDto.fromJson(json);
  }

  static String? _selectLogo(List<dynamic> logos) {
    if (logos.isEmpty) return null;

    final list = logos.cast<Map<String, dynamic>>();
    String? path(Map<String, dynamic> m) => m['file_path']?.toString();

    // 1) FR
    final fr =
        list
            .where((m) => (m['iso_639_1']?.toString().toLowerCase() == 'fr'))
            .toList()
          ..sort(
            (a, b) => ((b['vote_average'] as num? ?? 0).compareTo(
              a['vote_average'] as num? ?? 0,
            )),
          );
    if (fr.isNotEmpty) return path(fr.first);

    // 2) EN
    final en =
        list
            .where((m) => (m['iso_639_1']?.toString().toLowerCase() == 'en'))
            .toList()
          ..sort(
            (a, b) => ((b['vote_average'] as num? ?? 0).compareTo(
              a['vote_average'] as num? ?? 0,
            )),
          );
    if (en.isNotEmpty) return path(en.first);

    // 3) Sans langue
    final noLang = list.where((m) => m['iso_639_1'] == null).toList()
      ..sort(
        (a, b) => ((b['vote_average'] as num? ?? 0).compareTo(
          a['vote_average'] as num? ?? 0,
        )),
      );
    if (noLang.isNotEmpty) return path(noLang.first);

    // 4) Fallback : meilleur score
    list.sort(
      (a, b) => ((b['vote_average'] as num? ?? 0).compareTo(
        a['vote_average'] as num? ?? 0,
      )),
    );
    return path(list.first);
  }
}

class TmdbCollectionRefDto {
  TmdbCollectionRefDto({required this.id, required this.name, this.posterPath});

  factory TmdbCollectionRefDto.fromJson(Map<String, dynamic> json) =>
      TmdbCollectionRefDto(
        id: json['id'] as int,
        name: json['name']?.toString() ?? 'Collection',
        posterPath: json['poster_path']?.toString(),
      );

  final int id;
  final String name;
  final String? posterPath;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'poster_path': posterPath,
  };
}

class TmdbMovieCastDto {
  TmdbMovieCastDto({
    required this.id,
    required this.name,
    required this.character,
    required this.profilePath,
  });

  factory TmdbMovieCastDto.fromJson(Map<String, dynamic> json) {
    return TmdbMovieCastDto(
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

class TmdbMovieCrewDto {
  TmdbMovieCrewDto({required this.id, required this.name, required this.job});

  factory TmdbMovieCrewDto.fromJson(Map<String, dynamic> json) {
    return TmdbMovieCrewDto(
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

class TmdbMovieSummaryDto {
  TmdbMovieSummaryDto({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.backdropPath,
    required this.releaseDate,
    required this.voteAverage,
  });

  factory TmdbMovieSummaryDto.fromJson(Map<String, dynamic> json) {
    return TmdbMovieSummaryDto(
      id: json['id'] as int,
      title:
          json['title']?.toString() ??
          json['original_title']?.toString() ??
          'Untitled',
      posterPath: json['poster_path']?.toString(),
      backdropPath: json['backdrop_path']?.toString(),
      releaseDate: json['release_date']?.toString(),
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
    );
  }

  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double? voteAverage;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'poster_path': posterPath,
    'backdrop_path': backdropPath,
    'release_date': releaseDate,
    'vote_average': voteAverage,
  };
}
