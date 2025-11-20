import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/features/iptv/iptv.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/features/tv/presentation/models/tv_detail_view_model.dart';
import 'package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/value_objects/synopsis.dart';

class _FakeLogger implements AppLogger {
  @override
  void log(LogLevel level, String message, {String? category, Object? error, StackTrace? stackTrace}) {}
  @override
  void debug(String message, {String? category}) => log(LogLevel.debug, message, category: category);
  @override
  void info(String message, {String? category}) => log(LogLevel.info, message, category: category);
  @override
  void warn(String message, {String? category}) => log(LogLevel.warn, message, category: category);
  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) => log(LogLevel.error, message, error: error, stackTrace: stackTrace);
}

class _FakeIptvLocalRepository implements IptvLocalRepository {
  Set<int> seriesTmdbIds = {1};
  @override
  Future<Set<int>> getAvailableTmdbIds({XtreamPlaylistItemType? type}) async {
    return type == XtreamPlaylistItemType.series ? seriesTmdbIds : <int>{};
  }

  @override
  Future<List<XtreamAccount>> getAccounts() async => <XtreamAccount>[];
  @override
  Future<List<XtreamPlaylist>> getPlaylists(String accountId) async => <XtreamPlaylist>[];
  @override
  Future<Map<int, Map<int, EpisodeData>>> getAllEpisodesForSeries({required String accountId, required int seriesId}) async => <int, Map<int, EpisodeData>>{};
  @override
  Future<EpisodeData?> getEpisodeData({required String accountId, required int seriesId, required int seasonNumber, required int episodeNumber}) async => null;
  @override
  Future<void> saveEpisodes({required String accountId, required int seriesId, required Map<int, Map<int, EpisodeData>> episodes}) async {}
  @override
  Future<void> removeAccount(String id) async {}
  @override
  Future<void> saveAccount(XtreamAccount account) async {}
  @override
  Future<void> savePlaylists(String accountId, List<XtreamPlaylist> playlists) async {}
  @override
  Future<int?> getEpisodeId({required String accountId, required int seriesId, required int seasonNumber, required int episodeNumber}) async => null;
}

class _FakeTvRepository implements TvRepository {
  late TvShow lite;
  _FakeTvRepository() {
    lite = TvShow(
      id: const SeriesId('1'),
      tmdbId: 1,
      title: MediaTitle('Title'),
      synopsis: Synopsis('Overview'),
      poster: Uri.parse('http://p'),
      seasons: <Season>[
        Season(id: const SeasonId('1'), seasonNumber: 1, title: MediaTitle('S1')),
        Season(id: const SeasonId('2'), seasonNumber: 2, title: MediaTitle('S2')),
      ],
    );
  }

  @override
  Future<TvShow> getShow(SeriesId id) async => lite;
  @override
  Future<TvShow> getShowLite(SeriesId id) async => lite;
  @override
  Future<List<Season>> getSeasons(SeriesId id) async => lite.seasons;
  @override
  Future<List<Episode>> getEpisodes(SeriesId id, SeasonId seasonId) async {
    final s = int.parse(seasonId.value);
    return <Episode>[
      Episode(id: EpisodeId('e${s}1'), episodeNumber: 1, title: MediaTitle('E1'), airDate: DateTime(2024, 1, 1)),
      Episode(id: EpisodeId('e${s}2'), episodeNumber: 2, title: MediaTitle('E2'), airDate: DateTime(2099, 1, 1)),
    ];
  }
  @override
  Future<List<TvShowSummary>> getFeaturedShows() async => <TvShowSummary>[];
  @override
  Future<List<TvShowSummary>> getUserWatchlist() async => <TvShowSummary>[];
  @override
  Future<List<TvShowSummary>> getContinueWatching() async => <TvShowSummary>[];
  @override
  Future<List<TvShowSummary>> searchShows(String query) async => <TvShowSummary>[];
  @override
  Future<bool> isInWatchlist(SeriesId id) async => id.value == 'fav';
  @override
  Future<void> setWatchlist(SeriesId id, {required bool saved}) async {}
  @override
  Future<void> refreshMetadata(SeriesId id) async {}
}

void main() {
  test('tvDetailControllerProvider retourne un ViewModel', () async {
    final slFake = GetIt.asNewInstance();
    slFake.registerSingleton<AppLogger>(_FakeLogger());
    slFake.registerSingleton<IptvLocalRepository>(_FakeIptvLocalRepository());
    final repo = _FakeTvRepository();

    final container = ProviderContainer(
      overrides: [
        slProvider.overrideWithValue(slFake),
        tvRepositoryProvider.overrideWith((ref) => repo),
        tvDetailControllerProvider.overrideWith((ref, seriesId) async {
          final detail = await repo.getShow(SeriesId(seriesId));
          return TvDetailViewModel.fromDomain(detail: detail, language: 'fr-FR');
        }),
      ],
    );
    addTearDown(container.dispose);

    final vm = await container.read(tvDetailControllerProvider('1').future);
    expect(vm.title, 'Title');
    expect(vm.seasons.length, 2);
  });

  test('episodesBySeasonProvider charge les épisodes à la demande', () async {
    final slFake = GetIt.asNewInstance();
    slFake.registerSingleton<AppLogger>(_FakeLogger());
    slFake.registerSingleton<IptvLocalRepository>(_FakeIptvLocalRepository());
    final repo = _FakeTvRepository();

    final container = ProviderContainer(
      overrides: [
        slProvider.overrideWithValue(slFake),
        tvRepositoryProvider.overrideWith((ref) => repo),
      ],
    );
    addTearDown(container.dispose);

    final episodes = await container.read(
      episodesBySeasonProvider((seriesId: '1', seasonNumber: 1)).future,
    );
    expect(episodes.length, 2);
    expect(episodes.first.title.display, 'E1');
  });

  test('watchlistStatusProvider retourne le statut', () async {
    final slFake = GetIt.asNewInstance();
    slFake.registerSingleton<AppLogger>(_FakeLogger());
    slFake.registerSingleton<IptvLocalRepository>(_FakeIptvLocalRepository());
    final repo = _FakeTvRepository();

    final container = ProviderContainer(
      overrides: [
        slProvider.overrideWithValue(slFake),
        tvRepositoryProvider.overrideWith((ref) => repo),
      ],
    );
    addTearDown(container.dispose);

    final v1 = await container.read(watchlistStatusProvider('fav').future);
    final v2 = await container.read(watchlistStatusProvider('nope').future);
    expect(v1, true);
    expect(v2, false);
  });

  test('tvAvailabilityProvider pour tmdb et xtream', () async {
    final slFake = GetIt.asNewInstance();
    final iptv = _FakeIptvLocalRepository()..seriesTmdbIds = {1};
    slFake.registerSingleton<AppLogger>(_FakeLogger());
    slFake.registerSingleton<IptvLocalRepository>(iptv);
    final repo = _FakeTvRepository();

    final container = ProviderContainer(
      overrides: [
        slProvider.overrideWithValue(slFake),
        tvRepositoryProvider.overrideWith((ref) => repo),
      ],
    );
    addTearDown(container.dispose);

    final availableTmdb = await container.read(tvAvailabilityProvider('1').future);
    final availableXtream = await container.read(tvAvailabilityProvider('xtream:123').future);
    expect(availableTmdb, true);
    expect(availableXtream, true);
  });
}