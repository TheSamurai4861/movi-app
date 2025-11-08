import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/iptv/domain/entities/xtream_playlist_item.dart';

import 'package:movi/src/features/search/data/search_repository_impl.dart';
import 'package:movi/src/features/search/data/datasources/tmdb_search_remote_data_source.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_detail_dto.dart';
import 'package:movi/src/features/person/data/dtos/tmdb_person_detail_dto.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/core/network/network_executor.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/core/config/models/app_config.dart';
import 'package:movi/src/core/config/models/network_endpoints.dart';
import 'package:movi/src/core/config/models/feature_flags.dart';
import 'package:movi/src/core/config/models/app_metadata.dart';
import 'package:movi/src/core/config/env/environment.dart';
import 'package:dio/dio.dart';

class _StubSearchRemote extends TmdbSearchRemoteDataSource {
  _StubSearchRemote()
      : super(
          TmdbClient(
            NetworkExecutor(Dio()),
            AppConfig(
              environment: _FakeEnv(),
              network: const NetworkEndpoints(restBaseUrl: 'http://localhost', imageBaseUrl: 'http://localhost/img', tmdbApiKey: 'key'),
              featureFlags: const FeatureFlags(),
              metadata: const AppMetadata(version: '0.0.0', buildNumber: '0'),
            ),
            LocalePreferences(),
          ),
        );

  ({List<TmdbMovieSummaryDto> items, int totalPages}) movies = (items: const [], totalPages: 1);
  ({List<TmdbTvSummaryDto> items, int totalPages}) shows = (items: const [], totalPages: 1);
  ({List<TmdbPersonDetailDto> items, int totalPages}) people = (items: const [], totalPages: 1);

  @override
  Future<({List<TmdbMovieSummaryDto> items, int totalPages})> searchMovies(String query, {int page = 1}) async =>
      movies;

  @override
  Future<({List<TmdbTvSummaryDto> items, int totalPages})> searchShows(String query, {int page = 1}) async =>
      shows;

  @override
  Future<({List<TmdbPersonDetailDto> items, int totalPages})> searchPeople(String query, {int page = 1}) async =>
      people;
}

class _FakeEnv implements EnvironmentFlavor {
  @override
  AppEnvironment get environment => AppEnvironment.dev;
  @override
  String get label => 'dev';
  @override
  NetworkEndpoints get network => const NetworkEndpoints(restBaseUrl: 'http://localhost', imageBaseUrl: 'http://localhost/img', tmdbApiKey: 'key');
  @override
  FeatureFlags get defaultFlags => const FeatureFlags();
  @override
  AppMetadata get metadata => const AppMetadata(version: '0.0.0', buildNumber: '0');
  @override
  bool get isProduction => false;
}

class _StubIptvLocal extends IptvLocalRepository {
  _StubIptvLocal(this.availableMovies, this.availableShows);
  final Set<int> availableMovies;
  final Set<int> availableShows;

  @override
  Future<Set<int>> getAvailableTmdbIds({XtreamPlaylistItemType? type}) async {
    if (type == XtreamPlaylistItemType.series) return availableShows;
    return availableMovies;
  }
}

void main() {
  test('SearchRepositoryImpl filters movies/shows by IPTV availability and poster; preserves pagination', () async {
    final remote = _StubSearchRemote();
    remote.movies = (
      items: [
        TmdbMovieSummaryDto(id: 1, title: 'A', posterPath: '/a.jpg', backdropPath: null, releaseDate: '2020-01-01', voteAverage: 7.0),
        TmdbMovieSummaryDto(id: 2, title: 'NoPoster', posterPath: null, backdropPath: null, releaseDate: null, voteAverage: null),
        TmdbMovieSummaryDto(id: 3, title: 'C', posterPath: '/c.jpg', backdropPath: null, releaseDate: '2022-01-01', voteAverage: 8.0),
      ],
      totalPages: 4,
    );
    remote.shows = (
      items: [
        TmdbTvSummaryDto(id: 10, name: 'S1', posterPath: '/s1.jpg', backdropPath: null, firstAirDate: '2020-01-01', voteAverage: 7.0),
        TmdbTvSummaryDto(id: 11, name: 'S2', posterPath: null, backdropPath: null, firstAirDate: null, voteAverage: null),
        TmdbTvSummaryDto(id: 12, name: 'S3', posterPath: '/s3.jpg', backdropPath: null, firstAirDate: '2022-01-01', voteAverage: 8.0),
      ],
      totalPages: 3,
    );

    final iptv = _StubIptvLocal({1, 4}, {12});
    final repo = SearchRepositoryImpl(remote, const TmdbImageResolver(), iptv);

    final moviesPage = await repo.searchMovies('q', page: 2);
    expect(moviesPage.page, 2);
    expect(moviesPage.totalPages, 4);
    expect(moviesPage.items.length, 1); // only id 1 (has poster and available)
    expect(moviesPage.items.first.tmdbId, 1);

    final showsPage = await repo.searchShows('q');
    expect(showsPage.page, 1);
    expect(showsPage.totalPages, 3);
    expect(showsPage.items.length, 1); // only id 12 (has poster and available)
    expect(showsPage.items.first.tmdbId, 12);
  });
}
