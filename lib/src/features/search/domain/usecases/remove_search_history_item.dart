import 'package:movi/src/features/search/domain/repositories/search_history_repository.dart';

class RemoveSearchHistoryItem {
  const RemoveSearchHistoryItem(this._repo);
  final SearchHistoryRepository _repo;

  Future<void> call(String query) => _repo.remove(query);
}
