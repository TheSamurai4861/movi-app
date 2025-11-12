import '../../domain/repositories/search_repository.dart';
import '../../domain/entities/search_page.dart';
import '../../../tv/domain/entities/tv_show.dart';

class SearchShows {
  const SearchShows(this._repository);

  final SearchRepository _repository;

  Future<SearchPage<TvShowSummary>> call(String query, {int page = 1}) {
    return _repository.searchShows(query, page: page);
  }
}
