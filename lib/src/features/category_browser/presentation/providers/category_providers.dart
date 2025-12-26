// lib/src/features/category_browser/presentation/providers/category_providers.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/providers/repository_providers.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';
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

  List<ContentReference> _allItems = const <ContentReference>[];
  int _scanIndex = 0;
  int _loadToken = 0;

  @override
  CategoryState build() {
    _repo = ref.watch(categoryRepositoryProvider);
    _key = CategoryKey.parse(_visibleKey);
    // Rebuild when the current profile changes so we can re-apply parental filtering.
    ref.watch(currentProfileProvider);

    // Lancer le chargement initial dans une future microtask contrôlée.
    Future<void>(() => fetchFirstPage());
    return const CategoryState();
  }

  bool _hasRestrictions(Profile? profile) =>
      profile != null && (profile.isKid || profile.pegiLimit != null);

  Future<List<ContentReference>> _collectAllowed(Profile profile, int count) async {
    if (count <= 0) return const <ContentReference>[];
    if (_allItems.isEmpty || _scanIndex >= _allItems.length) {
      return const <ContentReference>[];
    }

    final policy = ref.read(parental.agePolicyProvider);
    final int batchSize = policy.maxConcurrentFilter <= 0 ? 1 : policy.maxConcurrentFilter;

    final allowed = <ContentReference>[];
    while (_scanIndex < _allItems.length && allowed.length < count) {
      final end =
          (_scanIndex + batchSize) > _allItems.length ? _allItems.length : (_scanIndex + batchSize);
      final batch = _allItems.sublist(_scanIndex, end);

      final results = await Future.wait<bool>(
        batch.map((item) async {
          final decision = await policy.evaluate(item, profile);
          return decision.isAllowed;
        }),
        eagerError: false,
      );

      for (var i = 0; i < batch.length; i++) {
        if (results[i]) {
          allowed.add(batch[i]);
          if (allowed.length >= count) break;
        }
      }

      _scanIndex = end;
    }

    return allowed;
  }

  Future<void> fetchFirstPage() async {
    final profile = ref.read(currentProfileProvider);

    final token = ++_loadToken;
    state = state.copyWith(isLoading: true, error: null, page: 1);
    try {
      final pageSize = state.pageSize;
      if (!_hasRestrictions(profile)) {
        final PaginatedResult<ContentReference> result = await _repo.getItemsPage(
          _key,
          1,
          pageSize,
        );
        if (token != _loadToken) return;
        state = state.copyWith(
          items: result.items,
          page: result.page,
          hasMore: result.hasMore,
          isLoading: false,
        );
        return;
      }

      // Restricted profiles: filter + "fill" by scanning through the cached full list
      // until we gather a full page of allowed items.
      _allItems = await _repo.getItems(_key);
      if (token != _loadToken) return;
      _scanIndex = 0;
      final filtered = await _collectAllowed(profile!, pageSize);
      if (token != _loadToken) return;
      final hasMore = _scanIndex < _allItems.length;

      state = state.copyWith(
        items: filtered,
        page: 1,
        hasMore: hasMore,
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
    final profile = ref.read(currentProfileProvider);
    final token = ++_loadToken;
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (!_hasRestrictions(profile)) {
        final nextPage = state.page + 1;
        final PaginatedResult<ContentReference> result = await _repo.getItemsPage(
          _key,
          nextPage,
          state.pageSize,
        );
        if (token != _loadToken) return;
        final newItems = <ContentReference>[...state.items, ...result.items];
        state = state.copyWith(
          items: newItems,
          page: result.page,
          hasMore: result.hasMore,
          isLoading: false,
        );
        return;
      }

      // Restricted profiles: collect another "logical page" of allowed items.
      if (_allItems.isEmpty) {
        _allItems = await _repo.getItems(_key);
        if (token != _loadToken) return;
        _scanIndex = 0;
      }

      final additional = await _collectAllowed(profile!, state.pageSize);
      if (token != _loadToken) return;
      final newItems = <ContentReference>[...state.items, ...additional];
      final hasMore = _scanIndex < _allItems.length;
      state = state.copyWith(
        items: newItems,
        page: state.page + 1,
        hasMore: hasMore,
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
