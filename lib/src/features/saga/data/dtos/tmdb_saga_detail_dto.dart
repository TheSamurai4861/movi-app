class TmdbSagaDetailDto {
  TmdbSagaDetailDto({
    required this.id,
    required this.name,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.parts,
  });

  factory TmdbSagaDetailDto.fromJson(Map<String, dynamic> json) {
    return TmdbSagaDetailDto(
      id: json['id'] as int,
      name: json['name']?.toString() ?? 'Collection',
      overview: json['overview']?.toString() ?? '',
      posterPath: json['poster_path']?.toString(),
      backdropPath: json['backdrop_path']?.toString(),
      parts: (json['parts'] as List<dynamic>? ?? const [])
          .map((part) => TmdbSagaPartDto.fromJson(part as Map<String, dynamic>))
          .toList(),
    );
  }

  final int id;
  final String name;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final List<TmdbSagaPartDto> parts;

  TmdbSagaDetailDto copyWith({List<TmdbSagaPartDto>? parts}) {
    return TmdbSagaDetailDto(
      id: id,
      name: name,
      overview: overview,
      posterPath: posterPath,
      backdropPath: backdropPath,
      parts: parts ?? this.parts,
    );
  }

  Map<String, dynamic> toCache() => {
    'id': id,
    'name': name,
    'overview': overview,
    'poster_path': posterPath,
    'backdrop_path': backdropPath,
    'parts': parts.map((part) => part.toJson()).toList(),
  };

  factory TmdbSagaDetailDto.fromCache(Map<String, dynamic> json) =>
      TmdbSagaDetailDto.fromJson(json);
}

class TmdbSagaPartDto {
  TmdbSagaPartDto({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.releaseDate,
    required this.voteAverage,
    this.runtime,
  });

  factory TmdbSagaPartDto.fromJson(Map<String, dynamic> json) {
    return TmdbSagaPartDto(
      id: json['id'] as int,
      title:
          json['title']?.toString() ??
          json['original_title']?.toString() ??
          'Untitled',
      posterPath: json['poster_path']?.toString(),
      releaseDate: json['release_date']?.toString(),
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      runtime: json['runtime'] as int?,
    );
  }

  final int id;
  final String title;
  final String? posterPath;
  final String? releaseDate;
  final double? voteAverage;
  final int? runtime;

  TmdbSagaPartDto copyWith({int? runtime}) {
    return TmdbSagaPartDto(
      id: id,
      title: title,
      posterPath: posterPath,
      releaseDate: releaseDate,
      voteAverage: voteAverage,
      runtime: runtime ?? this.runtime,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'poster_path': posterPath,
    'release_date': releaseDate,
    'vote_average': voteAverage,
    'runtime': runtime,
  };
}
