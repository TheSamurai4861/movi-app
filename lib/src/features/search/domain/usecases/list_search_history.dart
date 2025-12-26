import 'package:movi/src/features/search/domain/entities/search_history_item.dart';
import 'package:movi/src/features/search/domain/repositories/search_history_repository.dart';

class ListSearchHistory {
  const ListSearchHistory(this._repo);
  final SearchHistoryRepository _repo;

  Future<List<SearchHistoryItem>> call() => _repo.list();
}
