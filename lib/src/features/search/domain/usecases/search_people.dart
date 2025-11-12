import 'package:movi/src/features/search/domain/repositories/search_repository.dart';
import 'package:movi/src/features/search/domain/entities/search_page.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';

class SearchPeople {
  const SearchPeople(this._repository);

  final SearchRepository _repository;

  Future<SearchPage<PersonSummary>> call(String query, {int page = 1}) {
    return _repository.searchPeople(query, page: page);
  }
}
