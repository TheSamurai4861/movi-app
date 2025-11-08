import '../../../../shared/domain/entities/person_summary.dart';
import '../repositories/person_repository.dart';

class GetFeaturedPeople {
  const GetFeaturedPeople(this._repository);

  final PersonRepository _repository;

  Future<List<PersonSummary>> call() => _repository.getFeaturedPeople();
}
