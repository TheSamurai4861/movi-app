import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/features/saga/domain/repositories/saga_repository.dart';

class SearchSagas {
  const SearchSagas(this._repository);

  final SagaRepository _repository;

  Future<List<SagaSummary>> call(String query) =>
      _repository.searchSagas(query.trim());
}
