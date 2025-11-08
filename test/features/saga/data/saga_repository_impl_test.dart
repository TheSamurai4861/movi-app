import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/features/saga/data/repositories/saga_repository_impl.dart';
import 'package:movi/src/features/saga/data/datasources/tmdb_saga_remote_data_source.dart';
import 'package:movi/src/features/saga/data/datasources/saga_local_data_source.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/core/storage/repositories/watchlist_local_repository.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/features/saga/data/dtos/tmdb_saga_detail_dto.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

import '../../../helpers/in_memory_content_cache.dart';

class _FakeSagaRemote implements TmdbSagaRemoteDataSource {
  _FakeSagaRemote({this.detail, this.runtimeById = const {}, this.shouldThrow = false});

  TmdbSagaDetailDto? detail;
  final Map<int, int?> runtimeById;
  bool shouldThrow;
  int fetchCount = 0;

  @override
  Future<TmdbSagaDetailDto> fetchSaga(int id) async {
    fetchCount += 1;
    if (shouldThrow) throw Exception('network');
    if (detail == null) throw Exception('no detail');
    return detail!;
  }

  @override
  Future<int?> fetchMovieRuntime(int id) async => runtimeById[id];

  @override
  Future<List<TmdbSagaDetailDto>> searchSagas(String query) async => [];
}

class _FakeWatchlist implements WatchlistLocalRepository {
  _FakeWatchlist(this._entries);
  final List<WatchlistEntry> _entries;

  @override
  Future<bool> exists(String contentId, ContentType type) async =>
      _entries.any((e) => e.contentId == contentId && e.type == type);

  @override
  Future<List<WatchlistEntry>> readAll(ContentType type) async =>
      _entries.where((e) => e.type == type).toList(growable: false);

  @override
  Future<void> remove(String contentId, ContentType type) async {}

  @override
  Future<void> upsert(WatchlistEntry entry) async {}
}

void main() {
  test('getUserSagas maps from watchlist entries', () async {
    final cache = InMemoryContentCacheRepository();
    final local = SagaLocalDataSource(cache, LocalePreferences());
    final watchlist = _FakeWatchlist([
      WatchlistEntry(
        contentId: '10',
        type: ContentType.saga,
        title: 'Star Wars Collection',
        poster: Uri.parse('https://image.tmdb.org/t/p/w500/sw.jpg'),
        addedAt: DateTime.now(),
      ),
      WatchlistEntry(
        contentId: '999',
        type: ContentType.movie, // should be ignored
        title: 'Some Movie',
        poster: null,
        addedAt: DateTime.now(),
      ),
    ]);

    final repo = SagaRepositoryImpl(
      _FakeSagaRemote(),
      const TmdbImageResolver(),
      local,
      watchlist,
    );

    final result = await repo.getUserSagas('user-1');
    expect(result.length, 1);
    expect(result.first.id.toString(), '10');
    expect(result.first.title.value, 'Star Wars Collection');
    expect(result.first.cover, isNotNull);
  });

  test('getSaga caches remote and enriches runtime; uses cache on subsequent calls', () async {
    final cache = InMemoryContentCacheRepository();
    final local = SagaLocalDataSource(cache, LocalePreferences());
    final remote = _FakeSagaRemote(
      detail: TmdbSagaDetailDto(
        id: 10,
        name: 'Star Wars Collection',
        overview: '...',
        posterPath: '/sw.jpg',
        backdropPath: null,
        parts: [
          TmdbSagaPartDto(id: 11, title: 'A New Hope', posterPath: '/p1.jpg', releaseDate: '1977-05-25', voteAverage: 8.0, runtime: null),
          TmdbSagaPartDto(id: 12, title: 'Empire Strikes Back', posterPath: '/p2.jpg', releaseDate: '1980-05-17', voteAverage: 8.5, runtime: 124),
        ],
      ),
      runtimeById: const {11: 121},
    );
    final repo = SagaRepositoryImpl(remote, const TmdbImageResolver(), local, _FakeWatchlist(const []));

    // First call hits remote, enriches runtime, and caches
    final saga = await repo.getSaga(const SagaId('10'));
    expect(saga.title.value, 'Star Wars Collection');
    expect(saga.timeline.length, 2);
    expect(remote.fetchCount, 1);
    // Second call should use cache (no extra remote calls)
    final saga2 = await repo.getSaga(const SagaId('10'));
    expect(saga2.timeline.length, 2);
    expect(remote.fetchCount, 1);
  });

  test('getSaga falls back to cache when remote fails', () async {
    final cache = InMemoryContentCacheRepository();
    final local = SagaLocalDataSource(cache, LocalePreferences());
    final dto = TmdbSagaDetailDto(
      id: 10,
      name: 'Star Wars Collection',
      overview: '...',
      posterPath: '/sw.jpg',
      backdropPath: null,
      parts: [TmdbSagaPartDto(id: 11, title: 'A New Hope', posterPath: '/p1.jpg', releaseDate: '1977-05-25', voteAverage: 8.0, runtime: 121)],
    );
    await local.saveSagaDetail(dto);
    final remote = _FakeSagaRemote(shouldThrow: true);
    final repo = SagaRepositoryImpl(remote, const TmdbImageResolver(), local, _FakeWatchlist(const []));

    final saga = await repo.getSaga(const SagaId('10'));
    expect(saga.title.value, 'Star Wars Collection');
    expect(remote.fetchCount, 0); // cached path, no remote call
  });
}
