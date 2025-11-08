import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';
import 'package:movi/src/features/tv/data/datasources/tv_local_data_source.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_detail_dto.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_season_detail_dto.dart';
import 'package:movi/src/features/tv/data/repositories/tv_repository_impl.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

import '../../../helpers/in_memory_content_cache.dart';
import '../../../helpers/fake_watchlist_repository.dart';
import '../../../helpers/fake_continue_watching_repository.dart';

class _FakeTvRemoteDataSource implements TmdbTvRemoteDataSource {
  _FakeTvRemoteDataSource(this.detail, this.seasonDetails);

  final TmdbTvDetailDto detail;
  final Map<int, TmdbTvSeasonDetailDto> seasonDetails;
  int showFetchCount = 0;
  final Map<int, int> seasonFetchCount = {};

  @override
  Future<TmdbTvDetailDto> fetchShow(int id) async {
    showFetchCount += 1;
    return detail;
  }

  @override
  Future<TmdbTvSeasonDetailDto> fetchSeason(int showId, int seasonNumber) async {
    seasonFetchCount[seasonNumber] = (seasonFetchCount[seasonNumber] ?? 0) + 1;
    return seasonDetails[seasonNumber]!;
  }

  @override
  Future<List<TmdbTvSummaryDto>> fetchPopular() async => detail.recommendations;

  @override
  Future<List<TmdbTvSummaryDto>> searchShows(String query) async => detail.recommendations;
}

void main() {
  group('TvRepositoryImpl', () {
    late _FakeTvRemoteDataSource remote;
    late InMemoryContentCacheRepository cache;
    late TvRepository repository;

    setUp(() {
      remote = _FakeTvRemoteDataSource(
        TmdbTvDetailDto(
          id: 1,
          name: 'Test Show',
          overview: 'Overview',
          posterPath: '/poster.jpg',
          backdropPath: '/backdrop.jpg',
          logoPath: '/logo.png',
          firstAirDate: '2020-01-01',
          lastAirDate: '2021-01-01',
          status: 'Ended',
          voteAverage: 8.0,
          genres: ['Drama'],
          cast: [TmdbTvCastDto(id: 10, name: 'Actor', character: 'Hero', profilePath: '/actor.jpg')],
          creators: [TmdbTvCrewDto(id: 20, name: 'Creator', job: 'Creator')],
          seasons: [TmdbTvSeasonDto(id: 100, name: 'Season 1', overview: 'S1', posterPath: '/s1.jpg', airDate: '2020-01-01', seasonNumber: 1, episodeCount: 1)],
          recommendations: [TmdbTvSummaryDto(id: 2, name: 'Other', posterPath: '/poster2.jpg', backdropPath: '/backdrop2.jpg', firstAirDate: '2021-01-01', voteAverage: 7.5)],
        ),
        {
          1: TmdbTvSeasonDetailDto(
            id: 100,
            name: 'Season 1',
            airDate: '2020-01-01',
            episodes: [TmdbTvEpisodeDto(id: 1000, name: 'Ep1', airDate: '2020-01-01', voteAverage: 8.0, runtime: 42, stillPath: '/still.jpg', overview: 'Ep overview', episodeNumber: 1)],
          ),
        },
      );
      cache = InMemoryContentCacheRepository();
      repository = TvRepositoryImpl(
        remote,
        const TmdbImageResolver(),
        FakeWatchlistLocalRepository(),
        TvLocalDataSource(cache, LocalePreferences()),
        FakeContinueWatchingLocalRepository(),
      );
    });

    test('uses cached tv detail on repeated calls', () async {
      await repository.getShow(const SeriesId('1'));
      await repository.getShow(const SeriesId('1'));
      expect(remote.showFetchCount, 1);
      expect(remote.seasonFetchCount[1], 1);
    });

    test('uses cached season detail when listing seasons multiple times', () async {
      await repository.getSeasons(const SeriesId('1'));
      await repository.getSeasons(const SeriesId('1'));
      expect(remote.showFetchCount, 1);
      expect(remote.seasonFetchCount[1], 1);
    });

    test('uses cached season detail when requesting episodes repeatedly', () async {
      await repository.getEpisodes(const SeriesId('1'), const SeasonId('1'));
      await repository.getEpisodes(const SeriesId('1'), const SeasonId('1'));
      expect(remote.seasonFetchCount[1], 1);
    });
  });
}
