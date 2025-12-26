import 'package:movi/src/features/movie/domain/repositories/movie_repository.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

class GetMovieCredits {
  const GetMovieCredits(this._repository);

  final MovieRepository _repository;

  Future<List<PersonSummary>> call(MovieId id) => _repository.getCredits(id);
}
