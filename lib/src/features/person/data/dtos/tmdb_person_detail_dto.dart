class TmdbPersonDetailDto {
  TmdbPersonDetailDto({
    required this.id,
    required this.name,
    required this.biography,
    required this.profilePath,
    required this.birthDate,
    required this.deathDate,
    required this.placeOfBirth,
    required this.roles,
    required this.credits,
  });

  factory TmdbPersonDetailDto.fromJson(
    Map<String, dynamic> json,
    Map<String, dynamic> creditsJson,
  ) {
    return TmdbPersonDetailDto(
      id: json['id'] as int,
      name: json['name']?.toString() ?? 'Unknown',
      biography: json['biography']?.toString() ?? '',
      profilePath: json['profile_path']?.toString(),
      birthDate: json['birthday']?.toString(),
      deathDate: json['deathday']?.toString(),
      placeOfBirth: json['place_of_birth']?.toString(),
      roles: _extractRoles(json, creditsJson),
      credits:
          ((creditsJson['cast'] as List<dynamic>? ?? const []) +
                  (creditsJson['crew'] as List<dynamic>? ?? const []))
              .map(
                (item) =>
                    TmdbPersonCreditDto.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  final int id;
  final String name;
  final String biography;
  final String? profilePath;
  final String? birthDate;
  final String? deathDate;
  final String? placeOfBirth;
  final List<String> roles;
  final List<TmdbPersonCreditDto> credits;

  factory TmdbPersonDetailDto.fromCache(Map<String, dynamic> json) {
    return TmdbPersonDetailDto(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown',
      biography: json['biography'] as String? ?? '',
      profilePath: json['profile_path'] as String?,
      birthDate: json['birth_date'] as String?,
      deathDate: json['death_date'] as String?,
      placeOfBirth: json['place_of_birth'] as String?,
      roles: (json['roles'] as List<dynamic>? ?? const [])
          .map((role) => role.toString())
          .toList(),
      credits: (json['credits'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                TmdbPersonCreditDto.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toCache() => {
    'id': id,
    'name': name,
    'biography': biography,
    'profile_path': profilePath,
    'birth_date': birthDate,
    'death_date': deathDate,
    'place_of_birth': placeOfBirth,
    'roles': roles,
    'credits': credits.map((credit) => credit.toJson()).toList(),
  };

  static List<String> _extractRoles(
    Map<String, dynamic> json,
    Map<String, dynamic> creditsJson,
  ) {
    final roles = <String>{};
    final department = json['known_for_department']?.toString();
    if (department != null) roles.add(department);
    final crew = creditsJson['crew'] as List<dynamic>? ?? const [];
    for (final member in crew) {
      final job = member['job']?.toString();
      if (job != null && job.isNotEmpty) roles.add(job);
    }
    return roles.toList();
  }
}

class TmdbPersonCreditDto {
  TmdbPersonCreditDto({
    required this.id,
    required this.mediaType,
    required this.title,
    required this.posterPath,
    required this.character,
    required this.job,
    required this.releaseDate,
  });

  factory TmdbPersonCreditDto.fromJson(Map<String, dynamic> json) {
    return TmdbPersonCreditDto(
      id: json['id'] as int,
      mediaType: json['media_type']?.toString() ?? 'movie',
      title:
          (json['title'] ??
                  json['name'] ??
                  json['original_title'] ??
                  json['original_name'] ??
                  'Untitled')
              .toString(),
      posterPath: json['poster_path']?.toString(),
      character: json['character']?.toString(),
      job: json['job']?.toString(),
      releaseDate: (json['release_date'] ?? json['first_air_date'])?.toString(),
    );
  }

  final int id;
  final String mediaType;
  final String title;
  final String? posterPath;
  final String? character;
  final String? job;
  final String? releaseDate;

  Map<String, dynamic> toJson() => {
    'id': id,
    'media_type': mediaType,
    'title': title,
    'poster_path': posterPath,
    'character': character,
    'job': job,
    'release_date': releaseDate,
  };
}
