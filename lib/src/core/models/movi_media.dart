/// Type of media represented by [MoviMedia].
enum MoviMediaType { movie, series }

/// Base media data used by widgets like [MoviMediaCard].
sealed class MoviMedia {
  const MoviMedia({
    required this.id,
    required this.title,
    required this.poster,
    required this.year,
    required this.rating,
    required this.type,
  });

  final String id;
  final String title;
  final String poster;
  final String year;
  final String rating;
  final MoviMediaType type;
}

class MoviMovie extends MoviMedia {
  const MoviMovie({
    required super.id,
    required super.title,
    required super.poster,
    required super.year,
    required super.rating,
  }) : super(type: MoviMediaType.movie);
}

class MoviSeries extends MoviMedia {
  const MoviSeries({
    required super.id,
    required super.title,
    required super.poster,
    required super.year,
    required super.rating,
  }) : super(type: MoviMediaType.series);
}
