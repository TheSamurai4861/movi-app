import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/features/search/domain/entities/search_history_item.dart';
import 'package:movi/src/features/search/domain/repositories/search_history_repository.dart';
import 'package:movi/src/features/search/domain/usecases/add_search_query_to_history.dart';
import 'package:movi/src/features/search/domain/usecases/list_search_history.dart';
import 'package:movi/src/features/search/domain/usecases/remove_search_history_item.dart';

final searchHistoryRepositoryProvider = Provider<SearchHistoryRepository>((
  ref,
) {
  final locator = ref.watch(slProvider);
  return locator<SearchHistoryRepository>();
});

final listSearchHistoryProvider = FutureProvider<List<SearchHistoryItem>>((
  ref,
) async {
  final useCase = ListSearchHistory(ref.read(searchHistoryRepositoryProvider));
  return useCase();
});

class SearchHistoryController extends AsyncNotifier<List<SearchHistoryItem>> {
  late final SearchHistoryRepository _repo;

  @override
  Future<List<SearchHistoryItem>> build() async {
    _repo = ref.watch(searchHistoryRepositoryProvider);
    final useCase = ListSearchHistory(_repo);
    return useCase();
  }

  Future<void> add(String query) async {
    await AddSearchQueryToHistory(_repo)(query);
    await refresh();
  }

  Future<void> remove(String query) async {
    await RemoveSearchHistoryItem(_repo)(query);
    await refresh();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

final searchHistoryControllerProvider =
    AsyncNotifierProvider<SearchHistoryController, List<SearchHistoryItem>>(
      SearchHistoryController.new,
    );
