import 'package:equatable/equatable.dart';

enum MoviMediaType { movie, series }

class MoviMedia extends Equatable {
  const MoviMedia({
    required this.id,
    required this.title,
    required this.type,
    this.poster,
    this.year,
    this.rating,
  });

  final String id;
  final String title;
  final MoviMediaType type;
  final Uri? poster;
  final int? year;
  final double? rating;

  MoviMedia copyWith({
    String? id,
    String? title,
    MoviMediaType? type,
    Uri? poster,
    bool removePoster = false,
    int? year,
    bool removeYear = false,
    double? rating,
    bool removeRating = false,
  }) {
    return MoviMedia(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      poster: removePoster ? null : poster ?? this.poster,
      year: removeYear ? null : year ?? this.year,
      rating: removeRating ? null : rating ?? this.rating,
    );
  }

  @override
  List<Object?> get props => [id, title, type, poster, year, rating];

  @override
  String toString() =>
      'MoviMedia(id: $id, title: $title, type: $type, '
      'poster: ${poster?.toString() ?? "-"}, year: ${year ?? "-"}, rating: ${rating ?? "-"})';
}
