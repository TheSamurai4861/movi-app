import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/features/search/domain/entities/search_history_item.dart';
import 'package:movi/src/features/search/domain/repositories/search_history_repository.dart';
import 'package:movi/src/features/search/domain/usecases/add_search_query_to_history.dart';
import 'package:movi/src/features/search/domain/usecases/list_search_history.dart';
import 'package:movi/src/features/search/domain/usecases/remove_search_history_item.dart';

class FakeSearchHistoryRepository implements SearchHistoryRepository {
  final List<SearchHistoryItem> _items = [];
  Object? error;

  @override
  Future<void> add(String query) async {
    if (error != null) throw error!;
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _items.removeWhere((e) => e.query == trimmed);
    _items.insert(
      0,
      SearchHistoryItem(query: trimmed, savedAt: DateTime.now().toUtc()),
    );
    while (_items.length > 20) {
      _items.removeLast();
    }
  }

  @override
  Future<List<SearchHistoryItem>> list() async {
    if (error != null) throw error!;
    return List<SearchHistoryItem>.unmodifiable(_items);
  }

  @override
  Future<void> remove(String query) async {
    if (error != null) throw error!;
    _items.removeWhere((e) => e.query == query);
  }

  @override
  Future<void> clear() async {
    _items.clear();
  }
}

void main() {
  group('Search history use cases', () {
    test('list returns empty by default', () async {
      final repo = FakeSearchHistoryRepository();
      final listUseCase = ListSearchHistory(repo);

      final items = await listUseCase();

      expect(items, isEmpty);
    });

    test('save adds a query and list returns it', () async {
      final repo = FakeSearchHistoryRepository();
      final addUseCase = AddSearchQueryToHistory(repo);
      final listUseCase = ListSearchHistory(repo);

      await addUseCase('matrix');
      final items = await listUseCase();

      expect(items.length, 1);
      expect(items.first.query, 'matrix');
    });

    test('save deduplicates and keeps most recent first', () async {
      final repo = FakeSearchHistoryRepository();
      final addUseCase = AddSearchQueryToHistory(repo);
      final listUseCase = ListSearchHistory(repo);

      await addUseCase('matrix');
      await addUseCase('inception');
      await addUseCase('matrix');

      final items = await listUseCase();

      expect(items.length, 2);
      expect(items.first.query, 'matrix');
      expect(items[1].query, 'inception');
    });

    test('remove deletes a query from history', () async {
      final repo = FakeSearchHistoryRepository();
      final addUseCase = AddSearchQueryToHistory(repo);
      final listUseCase = ListSearchHistory(repo);
      final removeUseCase = RemoveSearchHistoryItem(repo);

      await addUseCase('matrix');
      await addUseCase('inception');

      await removeUseCase('matrix');
      final items = await listUseCase();

      expect(items.length, 1);
      expect(items.first.query, 'inception');
    });

    test('use cases propagate repository errors', () async {
      final repo = FakeSearchHistoryRepository();
      repo.error = Exception('cache error');
      final addUseCase = AddSearchQueryToHistory(repo);
      final listUseCase = ListSearchHistory(repo);
      final removeUseCase = RemoveSearchHistoryItem(repo);

      expect(() => addUseCase('x'), throwsException);
      expect(() => listUseCase(), throwsException);
      expect(() => removeUseCase('x'), throwsException);
    });
  });
}