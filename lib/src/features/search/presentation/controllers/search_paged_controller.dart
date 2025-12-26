import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/features/search/domain/usecases/search_paginated.dart';
import 'package:movi/src/features/search/domain/repositories/search_repository.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/features/search/presentation/models/search_results_args.dart';
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class SearchResultsState {
  const SearchResultsState({
    this.query = '',
    this.type = SearchResultsType.movies,
    this.itemsMovies = const <MovieSummary>[],
    this.itemsShows = const <TvShowSummary>[],
    this.page = 1,
    this.totalPages = 1,
    this.isLoading = false,
    this.error,
  });

  final String query;
  final SearchResultsType type;
  final List<MovieSummary> itemsMovies;
  final List<TvShowSummary> itemsShows;
  final int page;
  final int totalPages;
  final bool isLoading;
  final String? error;

  bool get hasMore => page < totalPages;

  SearchResultsState copyWith({
    String? query,
    SearchResultsType? type,
    List<MovieSummary>? itemsMovies,
    List<TvShowSummary>? itemsShows,
    int? page,
    int? totalPages,
    bool? isLoading,
    String? error,
  }) {
    return SearchResultsState(
      query: query ?? this.query,
      type: type ?? this.type,
      itemsMovies: itemsMovies ?? this.itemsMovies,
      itemsShows: itemsShows ?? this.itemsShows,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SearchPagedController extends Notifier<SearchResultsState> {
  SearchPagedController(this._args);
  final SearchResultsPageArgs _args;
  late final SearchPaginated _paginated;
  bool _profileListenerAttached = false;

  @override
  SearchResultsState build() {
    final locator = ref.watch(slProvider);
    final repo = locator<SearchRepository>();
    _paginated = SearchPaginated(repo);

    if (!_profileListenerAttached) {
      _profileListenerAttached = true;
      ref.listen(currentProfileProvider, (previous, next) {
        final changed =
            previous?.id != next?.id ||
            previous?.isKid != next?.isKid ||
            previous?.pegiLimit != next?.pegiLimit;
        if (!changed) return;
        unawaited(fetchFirstPage());
      });
    }

    Future.microtask(fetchFirstPage);
    return SearchResultsState(query: _args.query, type: _args.type);
  }

  Future<void> fetchFirstPage() async {
    state = state.copyWith(isLoading: true, error: null, page: 1);
    try {
      final profile = ref.read(currentProfileProvider);
      final bool hasRestrictions =
          profile != null && (profile.isKid || profile.pegiLimit != null);
      final policy = hasRestrictions ? ref.read(parental.agePolicyProvider) : null;

      if (state.type == SearchResultsType.movies) {
        final page = await _paginated.movies(state.query, page: 1);
        var items = page.items;
        if (policy != null) {
          final refs = items
              .map(
                (m) => ContentReference(
                  id: m.id.value,
                  type: ContentType.movie,
                  title: m.title,
                ),
              )
              .toList(growable: false);
          try {
            final allowed = await policy.filterAllowed(refs, profile!);
            final ids = allowed.map((r) => r.id).toSet();
            items = items.where((m) => ids.contains(m.id.value)).toList();
          } catch (_) {}
        }
        state = state.copyWith(
          itemsMovies: items,
          totalPages: page.totalPages,
          isLoading: false,
        );
      } else {
        final page = await _paginated.shows(state.query, page: 1);
        var items = page.items;
        if (policy != null) {
          final refs = items
              .map(
                (s) => ContentReference(
                  id: s.id.value,
                  type: ContentType.series,
                  title: s.title,
                ),
              )
              .toList(growable: false);
          try {
            final allowed = await policy.filterAllowed(refs, profile!);
            final ids = allowed.map((r) => r.id).toSet();
            items = items.where((s) => ids.contains(s.id.value)).toList();
          } catch (_) {}
        }
        state = state.copyWith(
          itemsShows: items,
          totalPages: page.totalPages,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Échec du chargement: $e',
      );
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    final next = state.page + 1;
    try {
      final profile = ref.read(currentProfileProvider);
      final bool hasRestrictions =
          profile != null && (profile.isKid || profile.pegiLimit != null);
      final policy = hasRestrictions ? ref.read(parental.agePolicyProvider) : null;

      if (state.type == SearchResultsType.movies) {
        final page = await _paginated.movies(state.query, page: next);
        var items = page.items;
        if (policy != null) {
          final refs = items
              .map(
                (m) => ContentReference(
                  id: m.id.value,
                  type: ContentType.movie,
                  title: m.title,
                ),
              )
              .toList(growable: false);
          try {
            final allowed = await policy.filterAllowed(refs, profile!);
            final ids = allowed.map((r) => r.id).toSet();
            items = items.where((m) => ids.contains(m.id.value)).toList();
          } catch (_) {}
        }
        state = state.copyWith(
          itemsMovies: [...state.itemsMovies, ...items],
          page: next,
          totalPages: page.totalPages,
          isLoading: false,
        );
      } else {
        final page = await _paginated.shows(state.query, page: next);
        var items = page.items;
        if (policy != null) {
          final refs = items
              .map(
                (s) => ContentReference(
                  id: s.id.value,
                  type: ContentType.series,
                  title: s.title,
                ),
              )
              .toList(growable: false);
          try {
            final allowed = await policy.filterAllowed(refs, profile!);
            final ids = allowed.map((r) => r.id).toSet();
            items = items.where((s) => ids.contains(s.id.value)).toList();
          } catch (_) {}
        }
        state = state.copyWith(
          itemsShows: [...state.itemsShows, ...items],
          page: next,
          totalPages: page.totalPages,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Échec du chargement: $e',
      );
    }
  }
}
