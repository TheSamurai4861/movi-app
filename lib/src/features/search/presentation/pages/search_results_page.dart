import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/focus/movi_focus_restore_policy.dart';
import 'package:movi/src/core/focus/movi_route_focus_boundary.dart';
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
  final FocusNode _backFocusNode = FocusNode(
    debugLabel: 'SearchResultsBack',
  );
  final FocusNode _firstResultFocusNode = FocusNode(
    debugLabel: 'SearchResultsFirstResult',
  );
  final FocusNode _retryFocusNode = FocusNode(
    debugLabel: 'SearchResultsRetry',
  );
  final FocusNode _loadMoreFocusNode = FocusNode(
    debugLabel: 'SearchResultsLoadMore',
  );

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
    _loadMoreFocusNode.dispose();
    super.dispose();
  }

  Future<void> _refreshResults() async {
    ref.invalidate(searchResultsControllerProvider(_args));
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

    return MoviRouteFocusBoundary(
      restorePolicy: MoviFocusRestorePolicy(
        initialFocusNode: initialFocusNode,
        fallbackFocusNode: _backFocusNode,
      ),
      requestInitialFocusOnMount: true,
      onUnhandledBack: () {
        if (!mounted) {
          return false;
        }
        Navigator.of(context).maybePop();
        return true;
      },
      debugLabel: 'SearchResultsRouteFocus',
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          top: true,
          bottom: false,
          child: Column(
            children: [
              MoviSubpageBackTitleHeader(
                title: 'Résultats — $title',
                onBack: () => Navigator.of(context).maybePop(),
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
                    loadMoreFocusNode: _loadMoreFocusNode,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResultsBody extends ConsumerWidget {
  const _SearchResultsBody({
    required this.state,
    required this.query,
    required this.backFocusNode,
    required this.firstResultFocusNode,
    required this.retryFocusNode,
    required this.loadMoreFocusNode,
  });

  final SearchResultsState state;
  final String query;
  final FocusNode backFocusNode;
  final FocusNode firstResultFocusNode;
  final FocusNode retryFocusNode;
  final FocusNode loadMoreFocusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (state.error != null && state.mediaList.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Requête: "$query"'),
          const SizedBox(height: AppSpacing.lg),
          Text(
            state.error!,
            style: const TextStyle(color: Colors.redAccent),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: MoviPrimaryButton(
              label: l10n.actionRetry,
              onPressed: () => ref.invalidate(searchResultsControllerProvider(
                SearchResultsPageArgs(query: state.query, type: state.type),
              )),
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
          Text('Requête: "$query"'),
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
          child: Text('Requête: "$query"'),
        ),
        MoviMediaGrid(
          itemCount: state.mediaList.length,
          firstItemFocusNode: firstResultFocusNode,
          footerFocusNode: state.hasMore ? loadMoreFocusNode : null,
          onExitUp: () {
            backFocusNode.requestFocus();
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
        if (state.hasMore) ...[
          const SizedBox(height: AppSpacing.lg),
          Focus(
            canRequestFocus: false,
            onKeyEvent: (_, event) {
              if (event is! KeyDownEvent) {
                return KeyEventResult.ignored;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                firstResultFocusNode.requestFocus();
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
                  event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                  event.logicalKey == LogicalKeyboardKey.arrowRight) {
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Center(
              child: MoviPrimaryButton(
                label: l10n.actionLoadMore,
                focusNode: loadMoreFocusNode,
                expand: false,
                loading: state.isLoadingMore,
                onPressed: state.isLoadingMore
                    ? null
                    : () => ref
                          .read(
                            searchResultsControllerProvider(
                              SearchResultsPageArgs(
                                query: state.query,
                                type: state.type,
                              ),
                            ).notifier,
                          )
                          .fetchNextPage(),
              ),
            ),
          ),
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
