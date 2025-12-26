import 'package:movi/src/features/person/domain/entities/person.dart';
import 'package:movi/src/features/person/domain/repositories/person_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

class GetPersonDetail {
  const GetPersonDetail(this._repository);

  final PersonRepository _repository;

  Future<Person> call(PersonId id) => _repository.getPerson(id);
}
