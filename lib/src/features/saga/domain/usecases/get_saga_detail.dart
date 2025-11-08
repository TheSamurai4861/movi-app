import '../entities/saga.dart';
import '../repositories/saga_repository.dart';
import '../../../../shared/domain/value_objects/media_id.dart';

class GetSagaDetail {
  const GetSagaDetail(this._repository);

  final SagaRepository _repository;

  Future<Saga> call(SagaId id) => _repository.getSaga(id);
}
