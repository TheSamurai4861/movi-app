import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/features/tv/domain/usecases/search_tv_shows.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

class _FakeTvRepository implements TvRepository {
  String? lastQuery;
  List<TvShowSummary> results = <TvShowSummary>[
    TvShowSummary(
      id: const SeriesId('s1'),
      tmdbId: 1,
      title: MediaTitle('A'),
      poster: Uri.parse('http://example.com/a.jpg'),
    ),
  ];

  @override
  Future<List<TvShowSummary>> searchShows(String query) async {
    lastQuery = query;
    return results;
  }

  @override
  Future<TvShow> getShow(SeriesId id) => throw UnimplementedError();
  @override
  Future<TvShow> getShowLite(SeriesId id) => throw UnimplementedError();
  @override
  Future<List<Season>> getSeasons(SeriesId id) => throw UnimplementedError();
  @override
  Future<List<Episode>> getEpisodes(SeriesId id, SeasonId seasonId) => throw UnimplementedError();
  @override
  Future<List<TvShowSummary>> getFeaturedShows() => throw UnimplementedError();
  @override
  Future<List<TvShowSummary>> getUserWatchlist() => throw UnimplementedError();
  @override
  Future<List<TvShowSummary>> getContinueWatching() => throw UnimplementedError();
  @override
  Future<bool> isInWatchlist(SeriesId id) => throw UnimplementedError();
  @override
  Future<void> setWatchlist(SeriesId id, {required bool saved}) => throw UnimplementedError();
  @override
  Future<void> refreshMetadata(SeriesId id) => throw UnimplementedError();
}

void main() {
  test('SearchTvShows trim la requête et délègue au repo', () async {
    final repo = _FakeTvRepository();
    final usecase = SearchTvShows(repo);

    final list = await usecase.call('  good  ');

    expect(repo.lastQuery, 'good');
    expect(list.length, 1);
    expect(list.first.title.display, 'A');
  });
}