enum MoviMediaType { movie, series }

class MoviMedia {
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
