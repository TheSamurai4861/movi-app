import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/features/tv/domain/usecases/toggle_tv_watchlist.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

class _FakeTvRepository implements TvRepository {
  SeriesId? lastId;
  bool? lastSaved;

  @override
  Future<void> setWatchlist(SeriesId id, {required bool saved}) async {
    lastId = id;
    lastSaved = saved;
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
  Future<List<TvShowSummary>> searchShows(String query) => throw UnimplementedError();
  @override
  Future<bool> isInWatchlist(SeriesId id) => throw UnimplementedError();
  @override
  Future<void> refreshMetadata(SeriesId id) => throw UnimplementedError();
}

void main() {
  test('ToggleTvWatchlist délègue au repository avec le flag', () async {
    final repo = _FakeTvRepository();
    final usecase = ToggleTvWatchlist(repo);
    final id = const SeriesId('s7');

    await usecase.call(id, saved: true);

    expect(repo.lastId, id);
    expect(repo.lastSaved, true);

    await usecase.call(id, saved: false);
    expect(repo.lastSaved, false);
  });
}