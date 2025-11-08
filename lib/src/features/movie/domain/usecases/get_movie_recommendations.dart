import '../entities/movie_summary.dart';
import '../repositories/movie_repository.dart';
import '../../../../shared/domain/value_objects/media_id.dart';

class GetMovieRecommendations {
  const GetMovieRecommendations(this._repository);

  final MovieRepository _repository;

  Future<List<MovieSummary>> call(MovieId id) => _repository.getRecommendations(id);
}
