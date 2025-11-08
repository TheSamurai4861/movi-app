import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/core/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/core/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/core/iptv/domain/value_objects/xtream_endpoint.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/features/home/data/repositories/home_feed_repository_impl.dart';
import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
import 'package:movi/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/movie/domain/entities/movie.dart';
import 'package:movi/src/features/movie/domain/repositories/movie_repository.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

class _FakeMoviesRemote implements TmdbMovieRemoteDataSource {
  _FakeMoviesRemote(this.trending);
  final List<TmdbMovieSummaryDto> trending;

  @override
  Future<List<TmdbMovieSummaryDto>> fetchTrendingMovies({String window = 'week'}) async => trending;

  // Unused in these tests
  @override
  Future<TmdbMovieDetailDto> fetchMovie(int id) => throw UnimplementedError();
  @override
  Future<List<TmdbMovieSummaryDto>> fetchPopular() => throw UnimplementedError();
  @override
  Future<List<TmdbMovieSummaryDto>> searchMovies(String query) => throw UnimplementedError();
}

class _FakeIptvLocal extends IptvLocalRepository {
  _FakeIptvLocal({required this.accounts, required this.playlistsByAccount, required this.available});
  final List<XtreamAccount> accounts;
  final Map<String, List<XtreamPlaylist>> playlistsByAccount;
  final Set<int> available;

  @override
  Future<List<XtreamAccount>> getAccounts() async => accounts;

  @override
  Future<List<XtreamPlaylist>> getPlaylists(String accountId) async => playlistsByAccount[accountId] ?? const [];

  @override
  Future<Set<int>> getAvailableTmdbIds({XtreamPlaylistItemType? type}) async => available;
}

class _FakeMovieRepo implements MovieRepository {
  _FakeMovieRepo(this.cw);
  final List<MovieSummary> cw;
  @override
  Future<List<MovieSummary>> getContinueWatching() async => cw;
  // Unused in these tests
  @override
  Future<List<PersonSummary>> getCredits(MovieId id) => throw UnimplementedError();
  @override
  Future<Movie> getMovie(MovieId id) => throw UnimplementedError();
  @override
  Future<List<MovieSummary>> getRecommendations(MovieId id) => throw UnimplementedError();
  @override
  Future<bool> isInWatchlist(MovieId id) => throw UnimplementedError();
  @override
  Future<List<MovieSummary>> searchMovies(String query) => throw UnimplementedError();
  @override
  Future<void> setWatchlist(MovieId id, {required bool saved}) => throw UnimplementedError();
}

class _FakeTvRepo implements TvRepository {
  _FakeTvRepo(this.cw);
  final List<TvShowSummary> cw;
  @override
  Future<List<TvShowSummary>> getContinueWatching() async => cw;
  // Unused in these tests
  @override
  Future<List<Episode>> getEpisodes(SeriesId id, SeasonId seasonId) => throw UnimplementedError();
  @override
  Future<List<TvShowSummary>> getFeaturedShows() => throw UnimplementedError();
  @override
  Future<List<Season>> getSeasons(SeriesId id) => throw UnimplementedError();
  @override
  Future<TvShow> getShow(SeriesId id) => throw UnimplementedError();
  @override
  Future<bool> isInWatchlist(SeriesId id) => throw UnimplementedError();
  @override
  Future<List<TvShowSummary>> searchShows(String query) => throw UnimplementedError();
  @override
  Future<void> setWatchlist(SeriesId id, {required bool saved}) => throw UnimplementedError();
  @override
  Future<List<TvShowSummary>> getUserWatchlist() => throw UnimplementedError();
}

void main() {
  group('HomeFeedRepositoryImpl', () {
    late AppStateController appState;

    setUp(() {
      appState = AppStateController(LocalePreferences());
      appState.addIptvSource('acc1');
    });

    test('getHeroMovies filters by IPTV availability and poster', () async {
      final remote = _FakeMoviesRemote([
        TmdbMovieSummaryDto(id: 1, title: 'A', posterPath: '/a.jpg', backdropPath: null, releaseDate: '2020-01-01', voteAverage: 7.0),
        TmdbMovieSummaryDto(id: 2, title: 'B', posterPath: null, backdropPath: null, releaseDate: '2021-01-01', voteAverage: 6.0),
        TmdbMovieSummaryDto(id: 3, title: 'C', posterPath: '/c.jpg', backdropPath: null, releaseDate: '2022-01-01', voteAverage: 8.0),
      ]);
      final iptv = _FakeIptvLocal(
        accounts: [XtreamAccount(id: 'acc1', alias: 'A1', endpoint: XtreamEndpoint.parse('http://h/'), username: 'u', password: 'p', status: XtreamAccountStatus.active, createdAt: DateTime.now())],
        playlistsByAccount: const {},
        available: {1, 4},
      );
      final repo = HomeFeedRepositoryImpl(
        remote,
        iptv,
        _FakeMovieRepo(const []),
        _FakeTvRepo(const []),
        const TmdbImageResolver(),
        appState,
      );

      final hero = await repo.getHeroMovies();
      // Only id 1 has poster and is available (2 has no poster, 3 not available)
      expect(hero.length, 1);
      expect(hero.first.tmdbId, 1);
    });

    test('getIptvCategoryLists aggregates per active account', () async {
      final remote = _FakeMoviesRemote(const []);
      final iptv = _FakeIptvLocal(
        accounts: [
          XtreamAccount(id: 'acc1', alias: 'A1', endpoint: XtreamEndpoint.parse('http://h/'), username: 'u', password: 'p', status: XtreamAccountStatus.active, createdAt: DateTime.now()),
          XtreamAccount(id: 'acc2', alias: 'A2', endpoint: XtreamEndpoint.parse('http://h2/'), username: 'u', password: 'p', status: XtreamAccountStatus.active, createdAt: DateTime.now()),
        ],
        playlistsByAccount: {
          'acc1': [
            XtreamPlaylist(
              id: 'cat1',
              accountId: 'acc1',
              title: 'Action',
              type: XtreamPlaylistType.movies,
              items: [
                XtreamPlaylistItem(accountId: 'acc1', categoryId: 'cat1', categoryName: 'Action', streamId: 10, title: 'Fight Club', type: XtreamPlaylistItemType.movie, posterUrl: 'https://image/p.jpg', tmdbId: 550),
                XtreamPlaylistItem(accountId: 'acc1', categoryId: 'cat1', categoryName: 'Action', streamId: 11, title: '', type: XtreamPlaylistItemType.movie, posterUrl: 'https://image/x.jpg', tmdbId: 551), // filtered (no title)
              ],
            ),
          ],
          'acc2': [
            XtreamPlaylist(id: 'catX', accountId: 'acc2', title: 'Other', type: XtreamPlaylistType.movies, items: const []),
          ],
        },
        available: const {},
      );

      final repo = HomeFeedRepositoryImpl(
        remote,
        iptv,
        _FakeMovieRepo(const []),
        _FakeTvRepo(const []),
        const TmdbImageResolver(),
        appState,
      );

      final lists = await repo.getIptvCategoryLists();
      expect(lists.keys.single, 'A1/Action');
      expect(lists['A1/Action']!.length, 1);
      expect(lists['A1/Action']!.first.id, '550');
    });

    test('getHeroMovies limits to 20 items', () async {
      // Build 30 trending items with posters
      final trending = <TmdbMovieSummaryDto>[];
      for (var i = 1; i <= 30; i++) {
        trending.add(TmdbMovieSummaryDto(
          id: i,
          title: 'M$i',
          posterPath: '/p$i.jpg',
          backdropPath: null,
          releaseDate: '2020-01-01',
          voteAverage: 7.0,
        ));
      }
      final remote = _FakeMoviesRemote(trending);
      // IPTV availability for all ids [1..30]
      final iptv = _FakeIptvLocal(
        accounts: [XtreamAccount(id: 'acc1', alias: 'A1', endpoint: XtreamEndpoint.parse('http://h/'), username: 'u', password: 'p', status: XtreamAccountStatus.active, createdAt: DateTime.now())],
        playlistsByAccount: const {},
        available: {for (var i = 1; i <= 30; i++) i},
      );
      final repo = HomeFeedRepositoryImpl(
        remote,
        iptv,
        _FakeMovieRepo(const []),
        _FakeTvRepo(const []),
        const TmdbImageResolver(),
        appState,
      );

      final hero = await repo.getHeroMovies();
      expect(hero.length, 20);
    });
  });
}
