import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/saga/domain/usecases/get_saga_detail.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/features/saga/domain/repositories/saga_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

class _Repo implements SagaRepository {
  Saga? saga;
  @override
  Future<Saga> getSaga(SagaId id) async {
    return saga!;
  }

  @override
  Future<List<SagaSummary>> getUserSagas(String userId) async => <SagaSummary>[];

  @override
  Future<List<SagaSummary>> searchSagas(String query) async => <SagaSummary>[];
}

void main() {
  test('GetSagaDetail forwards to repository', () async {
    final repo = _Repo();
    repo.saga = Saga(
      id: const SagaId('1'),
      tmdbId: 1,
      title: MediaTitle('T'),
      synopsis: null,
      cover: null,
      timeline: const <SagaEntry>[],
      tags: const <String>[],
      updatedAt: DateTime(2024, 1, 1),
    );
    final usecase = GetSagaDetail(repo);
    final result = await usecase(const SagaId('1'));
    expect(result.id.value, '1');
  });
}