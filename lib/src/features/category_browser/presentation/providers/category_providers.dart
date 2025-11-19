// lib/src/features/category_browser/presentation/providers/category_providers.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/config/providers/repository_providers.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/features/category_browser/domain/repositories/category_repository.dart';
import 'package:movi/src/features/category_browser/domain/value_objects/category_key.dart';
import 'package:movi/src/features/category_browser/domain/value_objects/paginated_result.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

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
  bool _initialized = false;

  @override
  CategoryState build() {
    _repo = ref.watch(categoryRepositoryProvider);
    _key = CategoryKey.parse(_visibleKey);
    if (!_initialized) {
      _initialized = true;
      // Lancer le chargement initial dans une future microtask contrôlée.
      Future<void>(() => fetchFirstPage());
    }
    return const CategoryState();
  }

  Future<void> fetchFirstPage() async {
    state = state.copyWith(isLoading: true, error: null, page: 1);
    try {
      final pageSize = state.pageSize;
      final PaginatedResult<ContentReference> result = await _repo.getItemsPage(
        _key,
        1,
        pageSize,
      );
      state = state.copyWith(
        items: result.items,
        page: result.page,
        hasMore: result.hasMore,
        isLoading: false,
      );
    } catch (e, st) {
      // Logger l'erreur pour le diagnostic, mais exposer un message générique au state.
      final logger = ref.read(slProvider)<AppLogger>();
      logger.error(
        '[Category] Échec du chargement initial pour clé=$_visibleKey: $e',
        e,
        st,
      );
      state = state.copyWith(isLoading: false, error: 'load_failed');
    }
  }

  Future<void> fetchNextPage() async {
    if (!state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final nextPage = state.page + 1;
      final PaginatedResult<ContentReference> result = await _repo.getItemsPage(
        _key,
        nextPage,
        state.pageSize,
      );
      final newItems = <ContentReference>[...state.items, ...result.items];
      state = state.copyWith(
        items: newItems,
        page: result.page,
        hasMore: result.hasMore,
        isLoading: false,
      );
    } catch (e, st) {
      final logger = ref.read(slProvider)<AppLogger>();
      logger.error(
        '[Category] Échec du chargement de la page suivante pour clé=$_visibleKey: $e',
        e,
        st,
      );
      state = state.copyWith(isLoading: false, error: 'load_failed');
    }
  }
}

final categoryControllerProvider =
    NotifierProvider.family<CategoryController, CategoryState, String>(
      CategoryController.new,
    );
