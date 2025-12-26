import 'package:movi/src/features/home/domain/repositories/home_feed_repository.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class RefreshHomeFeed {
  const RefreshHomeFeed(this._repo);

  final HomeFeedRepository _repo;

  Future<RefreshResult> call() async {
    final heroResult = await _repo.getHeroItems();
    final iptvResult = await _repo.getIptvCategoryLists();
    final movies = await _repo.getContinueWatchingMovies();
    final shows = await _repo.getContinueWatchingShows();

    List<ContentReference> hero = const <ContentReference>[];
    Map<String, List<ContentReference>> iptv =
        const <String, List<ContentReference>>{};

    heroResult.fold(ok: (value) => hero = value, err: (_) {});
    iptvResult.fold(ok: (value) => iptv = value, err: (_) {});

    return RefreshResult(
      hero: hero,
      iptv: iptv,
      cwMovies: movies,
      cwShows: shows,
    );
  }
}

class RefreshResult {
  const RefreshResult({
    required this.hero,
    required this.iptv,
    required this.cwMovies,
    required this.cwShows,
  });

  final List<ContentReference> hero;
  final Map<String, List<ContentReference>> iptv;
  final List<MovieSummary> cwMovies;
  final List<TvShowSummary> cwShows;
}
