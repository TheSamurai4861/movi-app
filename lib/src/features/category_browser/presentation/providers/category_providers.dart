// lib/src/features/category_browser/presentation/providers/category_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/features/category_browser/domain/repositories/category_repository.dart';
import 'package:movi/src/features/category_browser/domain/value_objects/category_key.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final locator = ref.watch(slProvider);
  return locator<CategoryRepository>();
});

class CategoryState {
  const CategoryState({
    this.items = const <ContentReference>[],
    this.page = 1,
    this.pageSize = 20,
    this.hasMore = false,
    this.isLoading = false,
    this.error,
  });

  final List<ContentReference> items;
  final int page;
  final int pageSize;
  final bool hasMore;
  final bool isLoading;
  final String? error;

  CategoryState copyWith({
    List<ContentReference>? items,
    int? page,
    int? pageSize,
    bool? hasMore,
    bool? isLoading,
    String? error,
  }) {
    return CategoryState(
      items: items ?? this.items,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class CategoryController extends Notifier<CategoryState> {
  CategoryController(this._visibleKey);
  final String _visibleKey;
  late final CategoryRepository _repo;
  late CategoryKey _key;

  @override
  CategoryState build() {
    _repo = ref.watch(categoryRepositoryProvider);
    _key = CategoryKey.parse(_visibleKey);
    Future.microtask(fetchFirstPage);
    return const CategoryState();
  }

  Future<void> fetchFirstPage() async {
    state = state.copyWith(isLoading: true, error: null, page: 1);
    try {
      final all = await _repo.getItems(_key);
      state = state.copyWith(items: all, hasMore: false, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Échec du chargement: $e',
      );
    }
  }

  Future<void> fetchNextPage() async {
    if (!state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      final all = await _repo.getItems(_key);
      final nextPage = state.page + 1;
      final end = nextPage * state.pageSize;
      final newItems = all.take(end).toList(growable: false);
      final hasMore = all.length > newItems.length;
      state = state.copyWith(
        items: newItems,
        page: nextPage,
        hasMore: hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Échec du chargement: $e',
      );
    }
  }
}

final categoryControllerProvider =
    NotifierProvider.family<CategoryController, CategoryState, String>(
      CategoryController.new,
    );
