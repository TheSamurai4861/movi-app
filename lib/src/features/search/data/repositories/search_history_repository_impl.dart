import '../../domain/entities/search_history_item.dart';
import '../../domain/repositories/search_history_repository.dart';
import '../datasources/search_history_local_data_source.dart';

class SearchHistoryRepositoryImpl implements SearchHistoryRepository {
  SearchHistoryRepositoryImpl(this._local);

  final SearchHistoryLocalDataSource _local;

  @override
  Future<void> add(String query) => _local.add(query);

  @override
  Future<List<SearchHistoryItem>> list() => _local.list();

  @override
  Future<void> remove(String query) => _local.remove(query);
}
