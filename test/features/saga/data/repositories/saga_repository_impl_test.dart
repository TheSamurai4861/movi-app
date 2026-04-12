import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/saga/data/datasources/saga_local_data_source.dart';
import 'package:movi/src/features/saga/data/datasources/tmdb_saga_remote_data_source.dart';
import 'package:movi/src/features/saga/data/dtos/tmdb_saga_detail_dto.dart';
import 'package:movi/src/features/saga/data/repositories/saga_repository_impl.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

void main() {
  tearDown(() async {
    await sl.reset();
  });

  test('getSaga deduplicates in-flight loads for same saga and language', () async {
    sl.registerSingleton<AppLogger>(_SilentLogger());
    final remote = _FakeTmdbSagaRemoteDataSource(
      detail: _sagaDto(id: 77, missingRuntimeParts: 4),
      language: 'fr-FR',
    );
    final repository = SagaRepositoryImpl(
      remote,
      const TmdbImageResolver(),
      _FakeSagaLocalDataSource(),
      _FakeWatchlistLocalRepository(),
    );

    final results = await Future.wait(
      <Future<dynamic>>[
        repository.getSaga(const SagaId('77')),
        repository.getSaga(const SagaId('77')),
        repository.getSaga(const SagaId('77')),
      ],
    );

    expect(results, hasLength(3));
    expect(remote.fetchSagaCount, 1);
    expect(remote.runtimeFetchCount, 4);
  });

  test('getSaga bounds runtime enrichment concurrency', () async {
    sl.registerSingleton<AppLogger>(_SilentLogger());
    final remote = _FakeTmdbSagaRemoteDataSource(
      detail: _sagaDto(id: 88, missingRuntimeParts: 8),
      language: 'fr-FR',
      runtimeDelay: const Duration(milliseconds: 20),
    );
    final repository = SagaRepositoryImpl(
      remote,
      const TmdbImageResolver(),
      _FakeSagaLocalDataSource(),
      _FakeWatchlistLocalRepository(),
    );

    final saga = await repository.getSaga(const SagaId('88'));

    expect(saga.timeline, hasLength(8));
    expect(remote.runtimeFetchCount, 8);
    expect(remote.maxConcurrentRuntimeFetches, lessThanOrEqualTo(3));
  });
}

TmdbSagaDetailDto _sagaDto({required int id, required int missingRuntimeParts}) {
  return TmdbSagaDetailDto(
    id: id,
    name: 'Saga $id',
    overview: 'Overview',
    posterPath: '/poster.jpg',
    backdropPath: '/backdrop.jpg',
    parts: List<TmdbSagaPartDto>.generate(
      missingRuntimeParts,
      (index) => TmdbSagaPartDto(
        id: 1000 + index,
        title: 'Movie $index',
        posterPath: '/m$index.jpg',
        releaseDate: '2020-01-0${(index % 9) + 1}',
        voteAverage: 7.0,
        runtime: null,
      ),
      growable: false,
    ),
  );
}

class _FakeTmdbSagaRemoteDataSource implements TmdbSagaRemoteDataSource {
  _FakeTmdbSagaRemoteDataSource({
    required this.detail,
    required this.language,
    this.runtimeDelay = Duration.zero,
  });

  final TmdbSagaDetailDto detail;
  final String language;
  final Duration runtimeDelay;

  int fetchSagaCount = 0;
  int runtimeFetchCount = 0;
  int _activeRuntimeFetches = 0;
  int maxConcurrentRuntimeFetches = 0;

  @override
  String get currentLanguageCode => language;

  @override
  Future<TmdbSagaDetailDto> fetchSaga(int id, {String? language}) async {
    fetchSagaCount++;
    return detail;
  }

  @override
  Future<int?> fetchMovieRuntime(int id) async {
    runtimeFetchCount++;
    _activeRuntimeFetches++;
    if (_activeRuntimeFetches > maxConcurrentRuntimeFetches) {
      maxConcurrentRuntimeFetches = _activeRuntimeFetches;
    }
    await Future<void>.delayed(runtimeDelay);
    _activeRuntimeFetches--;
    return 120;
  }

  @override
  Future<List<TmdbSagaDetailDto>> searchSagas(String query) async {
    return <TmdbSagaDetailDto>[detail];
  }
}

class _FakeSagaLocalDataSource implements SagaLocalDataSource {
  TmdbSagaDetailDto? _cached;

  @override
  Future<TmdbSagaDetailDto?> getSagaDetail(int sagaId) async {
    final cached = _cached;
    if (cached == null || cached.id != sagaId) return null;
    return cached;
  }

  @override
  Future<void> saveSagaDetail(TmdbSagaDetailDto dto) async {
    _cached = dto;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWatchlistLocalRepository implements WatchlistLocalRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SilentLogger implements AppLogger {
  @override
  void debug(String message, {String? category}) {}

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void info(String message, {String? category}) {}

  @override
  void log(
    LogLevel level,
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {}

  @override
  void warn(String message, {String? category}) {}
}
