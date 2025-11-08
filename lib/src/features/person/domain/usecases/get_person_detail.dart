import '../entities/person.dart';
import '../repositories/person_repository.dart';
import '../../../../shared/domain/value_objects/media_id.dart';

class GetPersonDetail {
  const GetPersonDetail(this._repository);

  final PersonRepository _repository;

  Future<Person> call(PersonId id) => _repository.getPerson(id);
}
