// lib/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart

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
    this.posterBackground,
  });

  factory TmdbMovieDetailDto.fromJson(Map<String, dynamic> json) {
    final images = json['images'] is Map
        ? (json['images'] as Map).cast<String, dynamic>()
        : null;
    final logos = images?['logos'] is List
        ? (images!['logos'] as List).cast<dynamic>()
        : const <dynamic>[];
    final credits = json['credits'] is Map
        ? (json['credits'] as Map).cast<String, dynamic>()
        : null;
    final rawCast = credits?['cast'] is List
        ? (credits!['cast'] as List).cast<dynamic>()
        : const <dynamic>[];
    final rawCrew = credits?['crew'] is List
        ? (credits!['crew'] as List).cast<dynamic>()
        : const <dynamic>[];
    final recs = json['recommendations'] is Map
        ? ((json['recommendations'] as Map).cast<String, dynamic>())['results']
        : null;
    final rawRecs = recs is List ? recs.cast<dynamic>() : const <dynamic>[];

    final cast = rawCast
        .whereType<Map>()
        .map((e) => TmdbMovieCastDto.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);

    final crew = rawCrew
        .whereType<Map>()
        .map((e) => TmdbMovieCrewDto.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);

    final recommendations = rawRecs
        .whereType<Map>()
        .map((e) => TmdbMovieSummaryDto.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);

    return TmdbMovieDetailDto(
      id: _asInt(json['id']) ?? 0,
      title:
          _stringOr(
            json['title'],
            _stringOr(json['original_title'], 'Untitled'),
          ) ??
          'Untitled',
      overview: _stringOr(json['overview'], '') ?? '',
      posterPath: _stringOr(json['poster_path']),
      posterBackground:
          _stringOr(json['poster_background']) ??
          _selectPosterBackground(images),
      backdropPath: _stringOr(json['backdrop_path']),
      logoPath: _selectLogo(logos),
      releaseDate: _stringOr(json['release_date']),
      runtime: _asInt(json['runtime']),
      voteAverage: _asDouble(json['vote_average']),
      genres:
          (json['genres'] is List
                  ? (json['genres'] as List)
                  : const <dynamic>[])
              .whereType<Map>()
              .map((g) => _stringOr(g['name'], '') ?? '')
              .where((name) => name.isNotEmpty)
              .toList(growable: false),
      cast: cast,
      directors: crew
          .where((m) => (m.job ?? '').toLowerCase() == 'director')
          .toList(growable: false),
      recommendations: recommendations,
      belongsToCollection: json['belongs_to_collection'] is Map
          ? TmdbCollectionRefDto.fromJson(
              (json['belongs_to_collection'] as Map).cast<String, dynamic>(),
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
  final String? posterBackground;

  Map<String, dynamic> toCache() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'overview': overview,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'logo_path': logoPath,
      'poster_background': posterBackground,
      'release_date': releaseDate,
      'runtime': runtime,
      'vote_average': voteAverage,
      'genres': genres
          .map((name) => <String, dynamic>{'name': name})
          .toList(growable: false),
      'credits': <String, dynamic>{
        'cast': cast.map((c) => c.toJson()).toList(growable: false),
        'crew': directors.map((d) => d.toJson()).toList(growable: false),
      },
      'recommendations': <String, dynamic>{
        'results': recommendations
            .map((r) => r.toJson())
            .toList(growable: false),
      },
      if (belongsToCollection != null)
        'belongs_to_collection': belongsToCollection!.toJson(),
      'images': <String, dynamic>{
        'logos': logoPath != null
            ? <Map<String, dynamic>>[
                <String, dynamic>{
                  'file_path': logoPath,
                  'vote_average': voteAverage,
                  'iso_639_1': null,
                },
              ]
            : <Map<String, dynamic>>[],
        'posters': const <Map<String, dynamic>>[],
      },
    };
  }

  factory TmdbMovieDetailDto.fromCache(Map<String, dynamic> json) =>
      TmdbMovieDetailDto.fromJson(json);

  static String? _selectPosterBackground(Map<String, dynamic>? images) {
    if (images == null) return null;
    final posters = images['posters'];
    if (posters is! List) return null;
    String? pathOf(Map<String, dynamic> m) => _stringOr(m['file_path']);
    bool okExt(String p) {
      final lower = p.toLowerCase();
      return lower.endsWith('.jpg') || lower.endsWith('.png');
    }

    final list = posters
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);

    for (final m in list) {
      final lang = _stringOr(m['iso_639_1']);
      final p = pathOf(m);
      if ((lang == null || lang.isEmpty) && p != null && okExt(p)) {
        return p;
      }
    }
    for (final m in list) {
      final lang = _stringOr(m['iso_639_1'])?.toLowerCase();
      final p = pathOf(m);
      if (lang == 'en' && p != null && okExt(p)) {
        return p;
      }
    }
    for (final m in list) {
      final p = pathOf(m);
      if (p != null && okExt(p)) {
        return p;
      }
    }
    return null;
  }

  static String? _selectLogo(List<dynamic> logos) {
    if (logos.isEmpty) return null;
    final list = logos
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);

    String? path(Map<String, dynamic> m) => _stringOr(m['file_path']);
    num score(Map<String, dynamic> m) =>
        (m['vote_average'] is num) ? (m['vote_average'] as num) : 0;

    int byScore(Map<String, dynamic> a, Map<String, dynamic> b) =>
        score(b).compareTo(score(a));

    List<Map<String, dynamic>> filterByLang(String code) {
      final lower = code.toLowerCase();
      return list
          .where((m) => _stringOr(m['iso_639_1'])?.toLowerCase() == lower)
          .toList()
        ..sort(byScore);
    }

    final fr = filterByLang('fr');
    if (fr.isNotEmpty) return path(fr.first);

    final en = filterByLang('en');
    if (en.isNotEmpty) return path(en.first);

    final noLang =
        list
            .where(
              (m) =>
                  m['iso_639_1'] == null ||
                  (_stringOr(m['iso_639_1']) ?? '').isEmpty,
            )
            .toList()
          ..sort(byScore);
    if (noLang.isNotEmpty) return path(noLang.first);

    final sorted = list.toList()..sort(byScore);
    return path(sorted.first);
  }
}

class TmdbCollectionRefDto {
  TmdbCollectionRefDto({required this.id, required this.name, this.posterPath});

  factory TmdbCollectionRefDto.fromJson(Map<String, dynamic> json) =>
      TmdbCollectionRefDto(
        id: _asInt(json['id']) ?? 0,
        name: _stringOr(json['name'], 'Collection') ?? 'Collection',
        posterPath: _stringOr(json['poster_path']),
      );

  final int id;
  final String name;
  final String? posterPath;

  Map<String, dynamic> toJson() => <String, dynamic>{
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

  factory TmdbMovieCastDto.fromJson(Map<String, dynamic> json) =>
      TmdbMovieCastDto(
        id: _asInt(json['id']) ?? 0,
        name: _stringOr(json['name'], 'Unknown') ?? 'Unknown',
        character: _stringOr(json['character']),
        profilePath: _stringOr(json['profile_path']),
      );

  final int id;
  final String name;
  final String? character;
  final String? profilePath;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'character': character,
    'profile_path': profilePath,
  };
}

class TmdbMovieCrewDto {
  TmdbMovieCrewDto({
    required this.id,
    required this.name,
    required this.job,
    this.profilePath,
  });

  factory TmdbMovieCrewDto.fromJson(Map<String, dynamic> json) =>
      TmdbMovieCrewDto(
        id: _asInt(json['id']) ?? 0,
        name: _stringOr(json['name'], 'Unknown') ?? 'Unknown',
        job: _stringOr(json['job']),
        profilePath: _stringOr(json['profile_path']),
      );

  final int id;
  final String name;
  final String? job;
  final String? profilePath;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'job': job,
    'profile_path': profilePath,
  };
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

  factory TmdbMovieSummaryDto.fromJson(Map<String, dynamic> json) =>
      TmdbMovieSummaryDto(
        id: _asInt(json['id']) ?? 0,
        title:
            _stringOr(
              json['title'],
              _stringOr(json['original_title'], 'Untitled'),
            ) ??
            'Untitled',
        posterPath: _stringOr(json['poster_path']),
        backdropPath: _stringOr(json['backdrop_path']),
        releaseDate: _stringOr(json['release_date']),
        voteAverage: _asDouble(json['vote_average']),
      );

  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double? voteAverage;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'poster_path': posterPath,
    'backdrop_path': backdropPath,
    'release_date': releaseDate,
    'vote_average': voteAverage,
  };
}

// -------------------- Helpers --------------------

int? _asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  final s = v.toString();
  if (s.isEmpty) return null;
  return int.tryParse(s);
}

double? _asDouble(Object? v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  final s = v.toString();
  if (s.isEmpty) return null;
  return double.tryParse(s);
}

String? _stringOr(Object? v, [String? fallback]) {
  if (v == null) return fallback;
  final s = v.toString();
  if (s.isEmpty) return fallback;
  return s;
}
