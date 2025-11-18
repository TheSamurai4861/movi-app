// lib/src/features/search/presentation/providers/search_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/iptv/iptv.dart';
import 'package:movi/src/features/search/domain/repositories/search_repository.dart';
import 'package:movi/src/features/search/domain/usecases/search_instant.dart';
import 'package:movi/src/features/search/domain/usecases/search_paginated.dart';
import 'package:movi/src/features/search/presentation/models/search_results_args.dart';
import 'package:movi/src/features/search/presentation/controllers/search_instant_controller.dart';
import 'package:movi/src/features/search/presentation/controllers/search_paged_controller.dart';
import 'package:movi/src/features/saga/domain/repositories/saga_repository.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

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

final searchResultsControllerProvider =
    NotifierProvider.family<
      SearchPagedController,
      SearchResultsState,
      SearchResultsPageArgs
    >(SearchPagedController.new);

/// Provider pour vérifier la disponibilité des films d'une saga dans la playlist
final sagaAvailabilityProvider = FutureProvider.family<Map<int, bool>, SagaSummary>((ref, saga) async {
  final sagaRepo = ref.watch(slProvider)<SagaRepository>();
  final iptvLocal = ref.watch(slProvider)<IptvLocalRepository>();
  
  try {
    final sagaDetail = await sagaRepo.getSaga(saga.id);
    final availableIds = await iptvLocal.getAvailableTmdbIds(type: XtreamPlaylistItemType.movie);
    
    final availabilityMap = <int, bool>{};
    for (final entry in sagaDetail.timeline) {
      if (entry.reference.type == ContentType.movie) {
        final movieId = int.tryParse(entry.reference.id);
        if (movieId != null) {
          availabilityMap[movieId] = availableIds.contains(movieId);
        }
      }
    }
    
    return availabilityMap;
  } catch (_) {
    return <int, bool>{};
  }
});

/// Provider pour filtrer les sagas qui ont au moins 1 film disponible dans la playlist
final filteredSagasProvider = FutureProvider.family<List<SagaSummary>, List<SagaSummary>>((ref, sagas) async {
  if (sagas.isEmpty) return const [];
  
  final filtered = <SagaSummary>[];
  for (final saga in sagas) {
    final availability = await ref.watch(sagaAvailabilityProvider(saga).future);
    if (availability.values.any((available) => available)) {
      filtered.add(saga);
    }
  }
  
  return filtered;
});

