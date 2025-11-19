import 'package:movi/src/features/home/domain/repositories/home_feed_repository.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/core/shared/failure.dart';
import 'package:movi/src/core/utils/result.dart';

class LoadHomeHero {
  const LoadHomeHero(this._repo);

  final HomeFeedRepository _repo;

  Future<Result<List<MovieSummary>, Failure>> call() => _repo.getHeroMovies();
}
