import '../entities/search_history_item.dart';
import '../repositories/search_history_repository.dart';

class ListSearchHistory {
  const ListSearchHistory(this._repo);
  final SearchHistoryRepository _repo;

  Future<List<SearchHistoryItem>> call() => _repo.list();
}