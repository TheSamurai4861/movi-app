import 'package:equatable/equatable.dart';

import '../../../../shared/domain/entities/person_summary.dart';
import 'movie_summary.dart';

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
