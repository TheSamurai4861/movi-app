import 'package:equatable/equatable.dart';

import 'media_title.dart';

enum ContentType { movie, series, saga, playlist, person }

class ContentReference extends Equatable {
  const ContentReference({
    required this.id,
    required this.title,
    required this.type,
    this.poster,
    this.year,
    this.rating,
  });

  final String id;
  final MediaTitle title;
  final ContentType type;
  final Uri? poster;
  final int? year;
  final double? rating;

  @override
  List<Object?> get props => [id, title, type, poster];
}
