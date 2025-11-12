import 'package:equatable/equatable.dart';

import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';

class MovieCredit extends Equatable {
  const MovieCredit({
    required this.movie,
    required this.person,
    required this.role,
  });

  final MovieSummary movie;
  final PersonSummary person;
  final String role;

  @override
  List<Object?> get props => [movie, person, role];
}
