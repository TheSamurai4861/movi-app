import '../entities/person.dart';
import '../repositories/person_repository.dart';
import '../../../../shared/domain/value_objects/media_id.dart';

class GetPersonFilmography {
  const GetPersonFilmography(this._repository);

  final PersonRepository _repository;

  Future<List<PersonCredit>> call(PersonId id) =>
      _repository.getFilmography(id);
}
