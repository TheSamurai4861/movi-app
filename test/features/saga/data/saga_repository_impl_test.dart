import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:movi/src/core/network/network_executor.dart';
import 'package:movi/src/core/config/models/network_endpoints.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/core/storage/services/cache_policy.dart';
import 'package:movi/src/core/storage/repositories/content_cache_repository.dart';
import 'package:movi/src/core/storage/repositories/watchlist_local_repository.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/features/saga/data/datasources/tmdb_saga_remote_data_source.dart';
import 'package:movi/src/features/saga/data/datasources/saga_local_data_source.dart';
import 'package:movi/src/features/saga/data/repositories/saga_repository_impl.dart';
import 'package:movi/src/features/saga/data/dtos/tmdb_saga_detail_dto.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

class InMemorySecureStorage extends FlutterSecureStorage {
  final Map<String, String> _store = <String, String>{};
  @override
  Future<String?> read({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async => _store[key];
  @override
  Future<void> write({required String key, required String? value, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }
}

class FakeContentCacheRepository extends ContentCacheRepository {
  final Map<String, Map<String, dynamic>> _payloads = <String, Map<String, dynamic>>{};
  final Map<String, DateTime> _updated = <String, DateTime>{};

  @override
  Future<void> put({required String key, required String type, required Map<String, dynamic> payload}) async {
    _payloads[key] = payload;
    _updated[key] = DateTime.now();
  }

  @override
  Future<Map<String, dynamic>?> get(String key, {CachePolicy? policy}) async {
    final payload = _payloads[key];
    if (payload == null) return null;
    if (policy != null) {
      final updatedAt = _updated[key] ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (policy.isExpired(updatedAt)) {
        _payloads.remove(key);
        _updated.remove(key);
        return null;
      }
    }
    return payload;
  }

  @override
  Future<Map<String, dynamic>?> getWithPolicy(String key, CachePolicy policy) async {
    return get(key, policy: policy);
  }
}

class _FakeWatchlist implements WatchlistLocalRepository {
  List<WatchlistEntry> entries = const <WatchlistEntry>[];

  @override
  Future<bool> exists(String contentId, ContentType type, {String? userId}) async => false;

  @override
  Future<void> remove(String contentId, ContentType type, {String? userId}) async {}

  @override
  Future<List<WatchlistEntry>> readAll(ContentType type, {String? userId}) async => entries;

  @override
  Future<void> upsert(WatchlistEntry entry) async {}
}

void main() {
  group('SagaRepositoryImpl.getUserSagas', () {
    late SagaRepositoryImpl repo;
    late _FakeWatchlist watchlist;

    setUp(() async {
      final remote = TmdbSagaRemoteDataSource(
        TmdbClient(
          executor: NetworkExecutor(Dio()),
          endpoints: const NetworkEndpoints(
            restBaseUrl: 'http://localhost',
            imageBaseUrl: 'http://localhost',
          ),
        ),
      );
      final prefs = await LocalePreferences.create(
        storage: InMemorySecureStorage(),
        defaultLanguageCode: 'fr-FR',
      );
      final local = SagaLocalDataSource(FakeContentCacheRepository(), prefs);
      watchlist = _FakeWatchlist();
      repo = SagaRepositoryImpl(
        remote,
        const TmdbImageResolver(),
        local,
        watchlist,
      );
    });

    test('maps watchlist entries to SagaSummary and preserves order', () async {
      watchlist.entries = <WatchlistEntry>[
        WatchlistEntry(
          contentId: '10',
          type: ContentType.saga,
          title: 'B Title',
          poster: Uri.parse('https://x/b.jpg'),
          addedAt: DateTime(2024, 10, 2),
          userId: 'u1',
        ),
        WatchlistEntry(
          contentId: '20',
          type: ContentType.saga,
          title: 'A Title',
          poster: Uri.parse('https://x/a.jpg'),
          addedAt: DateTime(2024, 10, 1),
          userId: 'u1',
        ),
      ];
      final result = await repo.getUserSagas('u1');

      expect(result.length, 2);
      expect(result.first.id.value, '10');
      expect(result.last.id.value, '20');
      expect(result.first.cover!.toString(), 'https://x/b.jpg');
    });

    test('filters out entries without poster', () async {
      watchlist.entries = <WatchlistEntry>[
        WatchlistEntry(
          contentId: '1',
          type: ContentType.saga,
          title: 'No Poster',
          poster: null,
          addedAt: DateTime.now(),
          userId: 'u1',
        ),
        WatchlistEntry(
          contentId: '2',
          type: ContentType.saga,
          title: 'With Poster',
          poster: Uri.parse('https://x/p.jpg'),
          addedAt: DateTime.now(),
          userId: 'u1',
        ),
      ];
      final result = await repo.getUserSagas('u1');
      expect(result.length, 1);
      expect(result.single.id.value, '2');
    });
  });

  group('SagaRepositoryImpl.getSaga runtime enrichment', () {
    test('fetches runtime only when missing and tolerates failures', () async {
      final remote = _StubSagaRemote();
      remote.detail = TmdbSagaDetailDto(
        id: 99,
        name: 'X',
        overview: '',
        posterPath: null,
        backdropPath: null,
        parts: [
          TmdbSagaPartDto(
            id: 1,
            title: 'A',
            posterPath: null,
            releaseDate: '2024-01-01',
            voteAverage: 7.5,
            runtime: null,
          ),
          TmdbSagaPartDto(
            id: 2,
            title: 'B',
            posterPath: null,
            releaseDate: '2024-01-02',
            voteAverage: 8.0,
            runtime: 120,
          ),
        ],
      );
      remote.runtimeById = {1: 100};

      final prefs = await LocalePreferences.create(
        storage: InMemorySecureStorage(),
        defaultLanguageCode: 'en-US',
      );
      final local = SagaLocalDataSource(FakeContentCacheRepository(), prefs);
      final repo = SagaRepositoryImpl(
        remote,
        const TmdbImageResolver(),
        local,
        _FakeWatchlist(),
      );

      final saga = await repo.getSaga(SagaId('99'));
      final runtimes = saga.timeline
          .where((e) => e.reference.type == ContentType.movie)
          .map((e) => e.reference.id)
          .toList();
      expect(remote.runtimeFetchCount, 1);
      expect(runtimes.length, 2);
    });

    test('keeps part when runtime fetch fails', () async {
      final remote = _StubSagaRemote();
      remote.detail = TmdbSagaDetailDto(
        id: 100,
        name: 'Y',
        overview: '',
        posterPath: null,
        backdropPath: null,
        parts: [
          TmdbSagaPartDto(
            id: 3,
            title: 'C',
            posterPath: null,
            releaseDate: '2024-02-01',
            voteAverage: 6.0,
            runtime: null,
          ),
        ],
      );
      remote.throwOnRuntime = true;

      final prefs = await LocalePreferences.create(
        storage: InMemorySecureStorage(),
        defaultLanguageCode: 'en-US',
      );
      final local = SagaLocalDataSource(FakeContentCacheRepository(), prefs);
      final repo = SagaRepositoryImpl(
        remote,
        const TmdbImageResolver(),
        local,
        _FakeWatchlist(),
      );

      final saga = await repo.getSaga(SagaId('100'));
      expect(saga.timeline.isNotEmpty, true);
      expect(remote.runtimeFetchCount, 1);
    });
  });
}

class _StubSagaRemote extends TmdbSagaRemoteDataSource {
  _StubSagaRemote()
      : super(
          TmdbClient(
            executor: NetworkExecutor(Dio()),
            endpoints: const NetworkEndpoints(
              restBaseUrl: 'http://localhost',
              imageBaseUrl: 'http://localhost',
            ),
          ),
        );

  late TmdbSagaDetailDto detail;
  Map<int, int?> runtimeById = <int, int?>{};
  bool throwOnRuntime = false;
  int runtimeFetchCount = 0;

  @override
  Future<TmdbSagaDetailDto> fetchSaga(int id, {String? language}) async {
    return detail;
  }

  @override
  Future<int?> fetchMovieRuntime(int id) async {
    runtimeFetchCount += 1;
    if (throwOnRuntime) {
      throw Exception('fail');
    }
    return runtimeById[id];
  }
}