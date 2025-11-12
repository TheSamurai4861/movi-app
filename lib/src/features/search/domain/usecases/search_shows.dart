import 'package:movi/src/features/search/domain/repositories/search_repository.dart';
import 'package:movi/src/features/search/domain/entities/search_page.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';

class SearchShows {
  const SearchShows(this._repository);

  final SearchRepository _repository;

  Future<SearchPage<TvShowSummary>> call(String query, {int page = 1}) {
    return _repository.searchShows(query, page: page);
  }
}
