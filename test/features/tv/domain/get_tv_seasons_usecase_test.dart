import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/features/tv/domain/usecases/get_tv_seasons.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

class _FakeTvRepository implements TvRepository {
  SeriesId? lastId;
  List<Season> seasons = <Season>[
    Season(
      id: const SeasonId('1'),
      seasonNumber: 1,
      title: MediaTitle('S1'),
    ),
    Season(
      id: const SeasonId('2'),
      seasonNumber: 2,
      title: MediaTitle('S2'),
    ),
  ];

  @override
  Future<List<Season>> getSeasons(SeriesId id) async {
    lastId = id;
    return seasons;
  }

  @override
  Future<TvShow> getShow(SeriesId id) => throw UnimplementedError();
  @override
  Future<TvShow> getShowLite(SeriesId id) => throw UnimplementedError();
  @override
  Future<List<Episode>> getEpisodes(SeriesId id, SeasonId seasonId) => throw UnimplementedError();
  @override
  Future<List<TvShowSummary>> getFeaturedShows() => throw UnimplementedError();
  @override
  Future<List<TvShowSummary>> getUserWatchlist() => throw UnimplementedError();
  @override
  Future<List<TvShowSummary>> getContinueWatching() => throw UnimplementedError();
  @override
  Future<List<TvShowSummary>> searchShows(String query) => throw UnimplementedError();
  @override
  Future<bool> isInWatchlist(SeriesId id) => throw UnimplementedError();
  @override
  Future<void> setWatchlist(SeriesId id, {required bool saved}) => throw UnimplementedError();
  @override
  Future<void> refreshMetadata(SeriesId id) => throw UnimplementedError();
}

void main() {
  test('GetTvSeasons délègue au repository', () async {
    final repo = _FakeTvRepository();
    final usecase = GetTvSeasons(repo);
    final id = const SeriesId('xyz');

    final result = await usecase.call(id);

    expect(repo.lastId, id);
    expect(result.length, 2);
    expect(result.first.title.display, 'S1');
    expect(result.last.seasonNumber, 2);
  });
}