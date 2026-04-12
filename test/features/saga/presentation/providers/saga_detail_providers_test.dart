import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/features/saga/domain/repositories/saga_repository.dart';
import 'package:movi/src/features/saga/domain/usecases/get_saga_detail.dart';
import 'package:movi/src/features/saga/presentation/providers/saga_detail_providers.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

void main() {
  test('saga providers share sagaCore and call repository only once', () async {
    final getIt = GetIt.asNewInstance();
    final sagaRepository = _CountingSagaRepository();
    getIt.registerSingleton<SagaRepository>(sagaRepository);
    getIt.registerSingleton<GetSagaDetail>(GetSagaDetail(sagaRepository));
    getIt.registerSingleton<TmdbClient>(_FakeTmdbClient());
    getIt.registerSingleton<TmdbImageResolver>(const TmdbImageResolver());
    getIt.registerSingleton<IptvLocalRepository>(
      _FakeIptvLocalRepository(<int>{1001}),
    );
    getIt.registerSingleton<HistoryLocalRepository>(
      _FakeHistoryLocalRepository(),
    );

    final container = ProviderContainer(
      overrides: [slProvider.overrideWithValue(getIt)],
    );
    addTearDown(container.dispose);
    addTearDown(() async => getIt.reset());

    final results = await Future.wait(
      <Future<Object>>[
        container.read(sagaDetailProvider('42').future),
        container.read(sagaMoviesAvailabilityProvider('42').future),
        container.read(sagaStartTargetProvider('42').future),
      ],
    );

    expect(results, hasLength(3));
    expect(sagaRepository.getSagaCalls, 1);
    final detail = results[0] as SagaDetailViewModel;
    final availability = results[1] as Map<int, bool>;
    final startTarget = results[2] as SagaStartTarget;
    expect(detail.movieCount, 2);
    expect(availability[1001], isTrue);
    expect(availability[1002], isFalse);
    expect(startTarget.movieId, '1001');
  });
}

class _CountingSagaRepository implements SagaRepository {
  int getSagaCalls = 0;

  @override
  Future<Saga> getSaga(SagaId id) async {
    getSagaCalls++;
    return Saga(
      id: id,
      tmdbId: 42,
      title: MediaTitle('Saga'),
      cover: Uri.parse('https://image.tmdb.org/t/p/w500/cover.jpg'),
      timeline: <SagaEntry>[
        SagaEntry(
          reference: ContentReference(
            id: '1001',
            title: MediaTitle('Movie 1'),
            type: ContentType.movie,
          ),
          duration: const Duration(minutes: 120),
          timelineYear: 2001,
        ),
        SagaEntry(
          reference: ContentReference(
            id: '1002',
            title: MediaTitle('Movie 2'),
            type: ContentType.movie,
          ),
          duration: const Duration(minutes: 115),
          timelineYear: 2003,
        ),
      ],
    );
  }

  @override
  Future<List<SagaSummary>> getUserSagas(String userId) async {
    return const <SagaSummary>[];
  }

  @override
  Future<List<SagaSummary>> searchSagas(String query) async {
    return const <SagaSummary>[];
  }
}

class _FakeTmdbClient implements TmdbClient {
  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
    String? language,
    dynamic cancelToken,
    int retries = 1,
    Duration? cacheTtl,
  }) async {
    return <String, dynamic>{
      'posters': <Map<String, dynamic>>[
        <String, dynamic>{'file_path': '/poster.jpg', 'iso_639_1': null},
      ],
      'backdrops': <Map<String, dynamic>>[
        <String, dynamic>{'file_path': '/backdrop.jpg', 'iso_639_1': null},
      ],
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeIptvLocalRepository implements IptvLocalRepository {
  _FakeIptvLocalRepository(this.availableIds);

  final Set<int> availableIds;

  @override
  Future<Set<int>> getAvailableTmdbIds({
    XtreamPlaylistItemType? type,
    Set<String>? accountIds,
  }) async {
    return availableIds;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHistoryLocalRepository implements HistoryLocalRepository {
  @override
  Future<List<HistoryEntry>> readAll(ContentType type, {String userId = 'default'}) async {
    return const <HistoryEntry>[];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
