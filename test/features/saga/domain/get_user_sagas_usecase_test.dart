import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/saga/domain/usecases/get_user_sagas.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/features/saga/domain/repositories/saga_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

class _Repo implements SagaRepository {
  List<SagaSummary> summaries = const <SagaSummary>[];

  @override
  Future<List<SagaSummary>> getUserSagas(String userId) async => summaries;

  @override
  Future<Saga> getSaga(SagaId id) async => throw UnimplementedError();

  @override
  Future<List<SagaSummary>> searchSagas(String query) async => <SagaSummary>[];
}

void main() {
  test('GetUserSagas forwards to repository', () async {
    final repo = _Repo();
    repo.summaries = <SagaSummary>[
      SagaSummary(id: const SagaId('10'), title: MediaTitle('A')),
    ];
    final usecase = GetUserSagas(repo);
    final result = await usecase('u1');
    expect(result.length, 1);
    expect(result.single.id.value, '10');
  });
}