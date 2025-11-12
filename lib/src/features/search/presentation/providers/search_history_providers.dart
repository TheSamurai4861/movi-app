import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/features/search/domain/entities/search_history_item.dart';
import 'package:movi/src/features/search/domain/repositories/search_history_repository.dart';
import 'package:movi/src/features/search/domain/usecases/add_search_query_to_history.dart';
import 'package:movi/src/features/search/domain/usecases/list_search_history.dart';
import 'package:movi/src/features/search/domain/usecases/remove_search_history_item.dart';

final searchHistoryRepositoryProvider = Provider<SearchHistoryRepository>((
  ref,
) {
  return sl<SearchHistoryRepository>();
});

final listSearchHistoryProvider = FutureProvider<List<SearchHistoryItem>>((
  ref,
) async {
  final useCase = ListSearchHistory(ref.read(searchHistoryRepositoryProvider));
  return useCase();
});

class SearchHistoryController
    extends StateNotifier<AsyncValue<List<SearchHistoryItem>>> {
  SearchHistoryController(this._repo) : super(const AsyncValue.data([])) {
    refresh();
  }

  final SearchHistoryRepository _repo;

  Future<void> add(String query) async {
    await AddSearchQueryToHistory(_repo)(query);
    await refresh();
  }

  Future<void> remove(String query) async {
    await RemoveSearchHistoryItem(_repo)(query);
    await refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final items = await ListSearchHistory(_repo)();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final searchHistoryControllerProvider =
    StateNotifierProvider<
      SearchHistoryController,
      AsyncValue<List<SearchHistoryItem>>
    >((ref) {
      return SearchHistoryController(ref.read(searchHistoryRepositoryProvider));
    });
