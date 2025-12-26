import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/features/person/domain/repositories/person_repository.dart';

class SearchPeople {
  const SearchPeople(this._repository);

  final PersonRepository _repository;

  Future<List<PersonSummary>> call(String query) =>
      _repository.searchPeople(query.trim());
}
