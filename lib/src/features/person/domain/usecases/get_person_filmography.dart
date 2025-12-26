import 'package:movi/src/features/person/domain/entities/person.dart';
import 'package:movi/src/features/person/domain/repositories/person_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

class GetPersonFilmography {
  const GetPersonFilmography(this._repository);

  final PersonRepository _repository;

  Future<List<PersonCredit>> call(PersonId id) =>
      _repository.getFilmography(id);
}
