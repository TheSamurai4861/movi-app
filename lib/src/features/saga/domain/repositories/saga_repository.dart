import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

abstract class SagaRepository {
  Future<Saga> getSaga(SagaId id);
  Future<List<SagaSummary>> getUserSagas(String userId);
  Future<List<SagaSummary>> searchSagas(String query);
}
