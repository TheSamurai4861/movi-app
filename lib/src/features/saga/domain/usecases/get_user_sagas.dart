import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/features/saga/domain/repositories/saga_repository.dart';

class GetUserSagas {
  const GetUserSagas(this._repository);

  final SagaRepository _repository;

  Future<List<SagaSummary>> call(String userId) =>
      _repository.getUserSagas(userId);
}
