import 'package:movi/src/features/home/domain/repositories/home_feed_repository.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';

class LoadHomeHero {
  const LoadHomeHero(this._repo);

  final HomeFeedRepository _repo;

  Future<List<MovieSummary>> call() => _repo.getHeroMovies();
}
