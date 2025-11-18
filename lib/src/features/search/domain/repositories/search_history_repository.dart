import 'package:movi/src/features/search/domain/entities/search_history_item.dart';

abstract class SearchHistoryRepository {
  Future<void> add(String query);
  Future<List<SearchHistoryItem>> list();
  Future<void> remove(String query);
  Future<void> clear();
}
