import 'package:equatable/equatable.dart';

import '../../../../shared/domain/entities/person_summary.dart';
import '../../../saga/domain/entities/saga.dart';
import '../../../../shared/domain/value_objects/content_rating.dart';
import '../../../../shared/domain/value_objects/media_id.dart';
import '../../../../shared/domain/value_objects/media_title.dart';
import '../../../../shared/domain/value_objects/synopsis.dart';

class Movie extends Equatable {
  const Movie({
    required this.id,
    this.tmdbId,
    required this.title,
    required this.synopsis,
    required this.duration,
    required this.poster,
    this.backdrop,
    required this.releaseDate,
    this.rating,
    required this.genres,
    required this.cast,
    required this.directors,
    this.tags = const [],
    this.sagaLink,
  });

  final MovieId id;
  final int? tmdbId;
  final MediaTitle title;
  final Synopsis synopsis;
  final Duration duration;
  final Uri poster;
  final Uri? backdrop;
  final DateTime releaseDate;
  final ContentRating? rating;
  final List<String> genres;
  final List<PersonSummary> cast;
  final List<PersonSummary> directors;
  final List<String> tags;
  final SagaSummary? sagaLink;

  @override
  List<Object?> get props => [
        id,
        tmdbId,
        title,
        synopsis,
        duration,
        poster,
        backdrop,
        releaseDate,
        rating,
        genres,
        cast,
        directors,
        tags,
        sagaLink,
      ];
}
