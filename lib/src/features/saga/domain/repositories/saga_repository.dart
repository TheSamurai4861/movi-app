import '../entities/saga.dart';
import '../../../../shared/domain/value_objects/media_id.dart';

abstract class SagaRepository {
  Future<Saga> getSaga(SagaId id);
  Future<List<SagaSummary>> getUserSagas(String userId);
  Future<List<SagaSummary>> searchSagas(String query);
}
