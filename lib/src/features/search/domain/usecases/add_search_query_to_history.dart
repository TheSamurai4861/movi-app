import 'package:movi/src/features/search/domain/repositories/search_history_repository.dart';

class AddSearchQueryToHistory {
  const AddSearchQueryToHistory(this._repo);
  final SearchHistoryRepository _repo;

  Future<void> call(String query) => _repo.add(query);
}
