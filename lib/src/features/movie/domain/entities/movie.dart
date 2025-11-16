import 'package:equatable/equatable.dart';

import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/shared/domain/value_objects/content_rating.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/value_objects/synopsis.dart';

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
    this.voteAverage,
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
  final double? voteAverage;
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
    voteAverage,
    genres,
    cast,
    directors,
    tags,
    sagaLink,
  ];
}
