import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/directional_edge.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/domain/focus_region_exit_map.dart';
import 'package:movi/src/core/focus/presentation/focus_region_scope.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/utils/navigation_helpers.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/features/search/presentation/controllers/search_paged_controller.dart';
import 'package:movi/src/features/search/presentation/models/search_results_args.dart';
import 'package:movi/src/features/search/presentation/providers/search_history_providers.dart';
import 'package:movi/src/features/search/presentation/providers/search_providers.dart';
import 'package:movi/src/shared/presentation/router/content_route_args.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';

class SearchResultsPage extends ConsumerStatefulWidget {
  const SearchResultsPage({super.key, this.args});

  final SearchResultsPageArgs? args;

  @override
  ConsumerState<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends ConsumerState<SearchResultsPage> {
  late final SearchResultsPageArgs _args;
  final FocusNode _backFocusNode = FocusNode(debugLabel: 'SearchResultsBack');
  final FocusNode _firstResultFocusNode = FocusNode(
    debugLabel: 'SearchResultsFirstResult',
  );
  final FocusNode _retryFocusNode = FocusNode(debugLabel: 'SearchResultsRetry');

  @override
  void initState() {
    super.initState();
    _args =
        widget.args ??
        const SearchResultsPageArgs(query: '', type: SearchResultsType.movies);
    final q = _args.query.trim();
    if (q.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(searchHistoryControllerProvider.notifier).add(q);
      });
    }
  }

  @override
  void dispose() {
    _backFocusNode.dispose();
    _firstResultFocusNode.dispose();
    _retryFocusNode.dispose();
    super.dispose();
  }

  Future<void> _refreshResults() async {
    ref.invalidate(searchResultsControllerProvider(_args));
  }

  bool _handleBack(BuildContext context) {
    if (!context.mounted) {
      return false;
    }
    final navigator = Navigator.of(context);
    if (!navigator.canPop()) {
      return false;
    }
    navigator.maybePop();
    return true;
  }

  KeyEventResult _handleBackKeyEvent(KeyEvent event, BuildContext context) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      return _handleBack(context)
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchResultsControllerProvider(_args));
    final title = state.type == SearchResultsType.movies
        ? AppLocalizations.of(context)!.moviesTitle
        : AppLocalizations.of(context)!.seriesTitle;

    final initialFocusNode = state.error != null
        ? _retryFocusNode
        : state.mediaList.isNotEmpty
        ? _firstResultFocusNode
        : _backFocusNode;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: FocusRegionScope(
        regionId: AppFocusRegionId.searchResultsPrimary,
        binding: FocusRegionBinding(
          resolvePrimaryEntryNode: () => initialFocusNode,
          resolveFallbackEntryNode: () => _backFocusNode,
        ),
        exitMap: FocusRegionExitMap({
          DirectionalEdge.left: AppFocusRegionId.shellSidebar,
        }),
        requestFocusOnMount: true,
        debugLabel: 'SearchResultsRegion',
        child: Focus(
          canRequestFocus: false,
          onKeyEvent: (_, event) => _handleBackKeyEvent(event, context),
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: SafeArea(
              top: true,
              bottom: false,
              child: Column(
                children: [
                  MoviSubpageBackTitleHeader(
                    title: 'RÃ©sultats - $title',
                    focusNode: _backFocusNode,
                    onBack: () => _handleBack(context),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refreshResults,
                      child: _SearchResultsBody(
                        state: state,
                        query: _args.query,
                        backFocusNode: _backFocusNode,
                        firstResultFocusNode: _firstResultFocusNode,
                        retryFocusNode: _retryFocusNode,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResultsBody extends ConsumerStatefulWidget {
  const _SearchResultsBody({
    required this.state,
    required this.query,
    required this.backFocusNode,
    required this.firstResultFocusNode,
    required this.retryFocusNode,
  });

  final SearchResultsState state;
  final String query;
  final FocusNode backFocusNode;
  final FocusNode firstResultFocusNode;
  final FocusNode retryFocusNode;

  @override
  ConsumerState<_SearchResultsBody> createState() => _SearchResultsBodyState();
}

class _SearchResultsBodyState extends ConsumerState<_SearchResultsBody> {
  static const int _wheelCooldownMs = 450;
  static const int _wheelExtentAfterThreshold = 320;
  int _lastWheelLoadMs = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final state = widget.state;
    final query = widget.query;
    final backFocusNode = widget.backFocusNode;
    final firstResultFocusNode = widget.firstResultFocusNode;
    final retryFocusNode = widget.retryFocusNode;

    if (state.error != null && state.mediaList.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('RequÃªte: "$query"'),
          const SizedBox(height: AppSpacing.lg),
          Text(state.error!, style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: MoviPrimaryButton(
              label: l10n.actionRetry,
              onPressed: () => ref.invalidate(
                searchResultsControllerProvider(
                  SearchResultsPageArgs(query: state.query, type: state.type),
                ),
              ),
              focusNode: retryFocusNode,
              expand: false,
            ),
          ),
        ],
      );
    }

    if (state.mediaList.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('RequÃªte: "$query"'),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Text(
              l10n.noResults,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text('RequÃªte: "$query"'),
        ),
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (!state.hasMore || state.isLoadingMore) return false;
            if (notification is! ScrollUpdateNotification) return false;
            if (notification.dragDetails != null) return false;
            final delta = notification.scrollDelta;
            if (delta == null || delta <= 0) return false;
            if (notification.metrics.extentAfter > _wheelExtentAfterThreshold) {
              return false;
            }
            final now = DateTime.now().millisecondsSinceEpoch;
            if (now - _lastWheelLoadMs < _wheelCooldownMs) return false;
            _lastWheelLoadMs = now;
            ref
                .read(
                  searchResultsControllerProvider(
                    SearchResultsPageArgs(query: state.query, type: state.type),
                  ).notifier,
                )
                .fetchNextPage();
            return false;
          },
          child: MoviMediaGrid(
            itemCount: state.mediaList.length,
            firstItemFocusNode: firstResultFocusNode,
            onExitUp: () {
              backFocusNode.requestFocus();
              return true;
            },
            onExitDown: () {
              if (state.hasMore && !state.isLoadingMore) {
                ref
                    .read(
                      searchResultsControllerProvider(
                        SearchResultsPageArgs(
                          query: state.query,
                          type: state.type,
                        ),
                      ).notifier,
                    )
                    .fetchNextPage();
              }
              return true;
            },
            itemBuilder: (context, index, focusNode, cardWidth, posterHeight) {
              final media = state.mediaList[index];
              return MoviMediaCard(
                media: media,
                width: cardWidth,
                height: posterHeight,
                focusNode: focusNode,
                onTap: (selectedMedia) {
                  if (selectedMedia.type == MoviMediaType.movie) {
                    navigateToMovieDetail(
                      context,
                      ref,
                      ContentRouteArgs.movie(selectedMedia.id),
                    );
                    return;
                  }
                  navigateToTvDetail(
                    context,
                    ref,
                    ContentRouteArgs.series(selectedMedia.id),
                  );
                },
              );
            },
          ),
        ),
        if (state.isLoadingMore) ...[
          const SizedBox(height: AppSpacing.lg),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }
}

extension on SearchResultsState {
  List<MoviMedia> get mediaList {
    final items = type == SearchResultsType.movies
        ? itemsMovies.map(
            (movie) => MoviMedia(
              id: movie.id.value,
              title: movie.title.display,
              poster: movie.poster,
              year: movie.releaseYear,
              type: MoviMediaType.movie,
            ),
          )
        : itemsShows.map(
            (show) => MoviMedia(
              id: show.id.value,
              title: show.title.display,
              poster: show.poster,
              type: MoviMediaType.series,
            ),
          );

    return items.toList(growable: false);
  }

  bool get isLoadingMore => isLoading && mediaList.isNotEmpty;
}
