import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/features/tv/domain/usecases/is_tv_show_in_watchlist.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

class _FakeTvRepository implements TvRepository {
  SeriesId? lastId;
  bool result = false;

  @override
  Future<bool> isInWatchlist(SeriesId id) async {
    lastId = id;
    return result;
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
  Future<void> setWatchlist(SeriesId id, {required bool saved}) => throw UnimplementedError();
  @override
  Future<void> refreshMetadata(SeriesId id) => throw UnimplementedError();
}

void main() {
  test('IsTvShowInWatchlist délègue au repository et retourne le bool', () async {
    final repo = _FakeTvRepository();
    final usecase = IsTvShowInWatchlist(repo);
    final id = const SeriesId('s9');

    repo.result = true;
    final v1 = await usecase.call(id);
    expect(repo.lastId, id);
    expect(v1, true);

    repo.result = false;
    final v2 = await usecase.call(id);
    expect(v2, false);
  });
}