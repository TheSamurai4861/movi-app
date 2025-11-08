import '../../domain/repositories/search_repository.dart';
import '../../domain/entities/search_page.dart';
import '../../../../shared/domain/entities/person_summary.dart';

class SearchPeople {
  const SearchPeople(this._repository);

  final SearchRepository _repository;

  Future<SearchPage<PersonSummary>> call(String query, {int page = 1}) {
    return _repository.searchPeople(query, page: page);
  }
}

