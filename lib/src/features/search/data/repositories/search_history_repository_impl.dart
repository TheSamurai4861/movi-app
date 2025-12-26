import 'package:movi/src/features/search/domain/entities/search_history_item.dart';
import 'package:movi/src/features/search/domain/repositories/search_history_repository.dart';
import 'package:movi/src/features/search/data/datasources/search_history_local_data_source.dart';

class SearchHistoryRepositoryImpl implements SearchHistoryRepository {
  SearchHistoryRepositoryImpl(this._local);

  final SearchHistoryLocalDataSource _local;

  @override
  Future<void> add(String query) => _local.add(query);

  @override
  Future<List<SearchHistoryItem>> list() => _local.list();

  @override
  Future<void> remove(String query) => _local.remove(query);

  @override
  Future<void> clear() => _local.clear();
}
