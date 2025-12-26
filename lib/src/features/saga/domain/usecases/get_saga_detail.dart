import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/features/saga/domain/repositories/saga_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

class GetSagaDetail {
  const GetSagaDetail(this._repository);

  final SagaRepository _repository;

  Future<Saga> call(SagaId id) => _repository.getSaga(id);
}
