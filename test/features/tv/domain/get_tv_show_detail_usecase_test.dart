import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/features/tv/domain/usecases/get_tv_show_detail.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/value_objects/synopsis.dart';

class _FakeTvRepository implements TvRepository {
  SeriesId? lastId;
  TvShow result = TvShow(
    id: const SeriesId('s1'),
    tmdbId: 10,
    title: MediaTitle('Show'),
    synopsis: Synopsis(''),
    poster: Uri.parse('http://example.com/p.jpg'),
  );

  @override
  Future<TvShow> getShow(SeriesId id) async {
    lastId = id;
    return result;
  }

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
  Future<void> setWatchlist(SeriesId id, {required bool saved}) => throw UnimplementedError();
  @override
  Future<void> refreshMetadata(SeriesId id) => throw UnimplementedError();
}

void main() {
  test('GetTvShowDetail délègue au repository', () async {
    final repo = _FakeTvRepository();
    final usecase = GetTvShowDetail(repo);
    final id = const SeriesId('abc');

    final show = await usecase.call(id);

    expect(repo.lastId, id);
    expect(show.id.value, 's1');
    expect(show.title.display, 'Show');
  });
}