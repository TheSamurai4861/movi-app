import 'package:equatable/equatable.dart';

import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

class MovieSummary extends Equatable {
  const MovieSummary({
    required this.id,
    this.tmdbId,
    required this.title,
    required this.poster,
    this.backdrop,
    this.releaseYear,
    this.tags = const [],
  });

  final MovieId id;
  final int? tmdbId;
  final MediaTitle title;
  final Uri poster;
  final Uri? backdrop;
  final int? releaseYear;
  final List<String> tags;

  @override
  List<Object?> get props => [
    id,
    tmdbId,
    title,
    poster,
    backdrop,
    releaseYear,
    tags,
  ];
}
