// lib/src/features/search/presentation/providers/search_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/features/search/domain/repositories/search_repository.dart';
import 'package:movi/src/features/search/domain/usecases/search_instant.dart';
import 'package:movi/src/features/search/domain/usecases/search_paginated.dart';
import 'package:movi/src/features/search/presentation/models/search_results_args.dart';
import 'package:movi/src/features/search/presentation/controllers/search_instant_controller.dart';
import 'package:movi/src/features/search/presentation/controllers/search_paged_controller.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final locator = ref.watch(slProvider);
  return locator<SearchRepository>();
});

final searchInstantUseCaseProvider = Provider<SearchInstant>(
  (ref) => SearchInstant(ref.watch(searchRepositoryProvider)),
);

final searchPaginatedUseCaseProvider = Provider<SearchPaginated>(
  (ref) => SearchPaginated(ref.watch(searchRepositoryProvider)),
);

final searchControllerProvider =
    NotifierProvider<SearchInstantController, SearchState>(
  SearchInstantController.new,
);

final searchResultsControllerProvider = NotifierProvider.family<
  SearchPagedController,
  SearchResultsState,
  SearchResultsPageArgs
>(SearchPagedController.new);
