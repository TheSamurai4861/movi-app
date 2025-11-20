import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/features/tv/domain/usecases/get_season_episodes.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

class _FakeTvRepository implements TvRepository {
  SeriesId? lastShowId;
  SeasonId? lastSeasonId;
  List<Episode> episodes = <Episode>[
    Episode(
      id: const EpisodeId('e1'),
      episodeNumber: 1,
      title: MediaTitle('E1'),
    ),
    Episode(
      id: const EpisodeId('e2'),
      episodeNumber: 2,
      title: MediaTitle('E2'),
    ),
  ];

  @override
  Future<List<Episode>> getEpisodes(SeriesId id, SeasonId seasonId) async {
    lastShowId = id;
    lastSeasonId = seasonId;
    return episodes;
  }

  @override
  Future<TvShow> getShow(SeriesId id) => throw UnimplementedError();
  @override
  Future<TvShow> getShowLite(SeriesId id) => throw UnimplementedError();
  @override
  Future<List<Season>> getSeasons(SeriesId id) => throw UnimplementedError();
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
  test('GetSeasonEpisodes délègue au repository avec identifiants', () async {
    final repo = _FakeTvRepository();
    final usecase = GetSeasonEpisodes(repo);
    final showId = const SeriesId('s42');
    final seasonId = const SeasonId('2');

    final result = await usecase.call(showId, seasonId);

    expect(repo.lastShowId, showId);
    expect(repo.lastSeasonId, seasonId);
    expect(result.length, 2);
    expect(result.first.title.display, 'E1');
    expect(result.last.episodeNumber, 2);
  });
}