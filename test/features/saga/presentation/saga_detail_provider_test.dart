import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/di/injector.dart';
import 'package:dio/dio.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/core/config/models/network_endpoints.dart';
import 'package:movi/src/core/network/network_executor.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/features/saga/domain/repositories/saga_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/features/saga/domain/usecases/get_saga_detail.dart';
import 'package:movi/src/features/saga/presentation/providers/saga_detail_providers.dart';

class _FakeExecutor extends NetworkExecutor {
  _FakeExecutor() : super(Dio());

  @override
  Future<R> run<T, R>({
    required NetworkCall<T> request,
    required R Function(Response<T> response) mapper,
    String? concurrencyKey,
    int? maxConcurrent,
    int retries = 0,
    RetryEvaluator? retryIf,
    Duration baseDelay = const Duration(milliseconds: 300),
    Duration maxDelay = const Duration(seconds: 5),
    bool jitter = true,
    String? dedupKey,
    Duration? cacheTtl,
    CancelToken? cancelToken,
    AttemptHook? onAttemptStart,
    AttemptHook? onAttemptEnd,
  }) async {
    final resp = Response<T>(
      requestOptions: RequestOptions(path: '/3/collection/5/images'),
      data: {
        'posters': [
          {'file_path': '/p.jpg', 'iso_639_1': null},
        ],
        'backdrops': [
          {'file_path': '/b.jpg', 'iso_639_1': null},
        ],
      } as T,
      statusCode: 200,
    );
    return mapper(resp);
  }
}

class _FakeGetSagaDetail extends GetSagaDetail {
  _FakeGetSagaDetail() : super(_Repo());
}

  class _Repo implements SagaRepository {
  @override
  Future<Saga> getSaga(SagaId id) async {
    return Saga(
      id: id,
      tmdbId: 5,
      title: MediaTitle('T'),
      synopsis: null,
      cover: null,
      timeline: const <SagaEntry>[],
      tags: const <String>[],
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<SagaSummary>> getUserSagas(String userId) async => <SagaSummary>[];

  @override
  Future<List<SagaSummary>> searchSagas(String query) async => <SagaSummary>[];
}

  void main() {
  test('sagaDetailProvider uses use case and resolves images with null language', () async {
    final client = TmdbClient(
      executor: _FakeExecutor(),
      endpoints: const NetworkEndpoints(restBaseUrl: 'http://localhost', imageBaseUrl: 'http://img/'),
    );
    replace<TmdbClient>(client);
    replace<TmdbImageResolver>(const TmdbImageResolver(baseUrl: 'http://img/'));
    final getIt = sl;
    if (!getIt.isRegistered<GetSagaDetail>()) {
      getIt.registerLazySingleton<GetSagaDetail>(() => _FakeGetSagaDetail());
    } else {
      replace<GetSagaDetail>(_FakeGetSagaDetail());
    }

    final container = ProviderContainer(overrides: []);
    addTearDown(container.dispose);
    final result = await container.read(sagaDetailProvider('5').future);
    expect(result.poster!.toString(), 'http://img/w500/p.jpg');
    expect(result.backdrop!.toString(), 'http://img/w780/b.jpg');
  });
}