// lib/src/features/search/presentation/pages/search_results_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';

import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/utils/navigation_helpers.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/src/shared/presentation/router/content_route_args.dart';
import 'package:movi/src/features/search/presentation/models/search_results_args.dart';
import 'package:movi/src/features/search/presentation/providers/search_providers.dart';
import 'package:movi/src/features/search/presentation/controllers/search_paged_controller.dart';
import 'package:movi/src/features/search/presentation/providers/search_history_providers.dart';

class SearchResultsPage extends ConsumerStatefulWidget {
  const SearchResultsPage({super.key, this.args});

  final SearchResultsPageArgs? args;

  @override
  ConsumerState<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends ConsumerState<SearchResultsPage> {
  late final SearchResultsPageArgs _args;

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
  Widget build(BuildContext context) {
    final state = ref.watch(searchResultsControllerProvider(_args));

    final title = state.type == SearchResultsType.movies
        ? AppLocalizations.of(context)!.moviesTitle
        : AppLocalizations.of(context)!.seriesTitle;
    return Scaffold(
      appBar: AppBar(title: Text('Résultats — $title')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Requête: "${state.query}"'),
              const SizedBox(height: AppSpacing.md),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    state.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(searchResultsControllerProvider(_args));
                  },
                  child: _ResultsGrid(state: state),
                ),
              ),
              if (state.hasMore)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: ElevatedButton(
                    onPressed: () => ref
                        .read(searchResultsControllerProvider(_args).notifier)
                        .fetchNextPage(),
                    child: Text(AppLocalizations.of(context)!.actionLoadMore),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultsGrid extends ConsumerWidget {
  const _ResultsGrid({required this.state});

  final SearchResultsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = state.type == SearchResultsType.movies
        ? state.itemsMovies.map(
            (m) => MoviMedia(
              id: m.id.value,
              title: m.title.display,
              poster: m.poster,
              year: m.releaseYear,
              type: MoviMediaType.movie,
            ),
          )
        : state.itemsShows.map(
            (s) => MoviMedia(
              id: s.id.value,
              title: s.title.display,
              poster: s.poster,
              type: MoviMediaType.series,
            ),
          );

    final mediaList = items.toList(growable: false);

    if (mediaList.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noResults));
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.66,
      ),
      itemCount: mediaList.length,
      itemBuilder: (context, index) {
        return MoviMediaCard(
          media: mediaList[index],
          onTap: (m) {
            if (m.type == MoviMediaType.movie) {
              navigateToMovieDetail(context, ref, ContentRouteArgs.movie(m.id));
            } else {
              navigateToTvDetail(context, ref, ContentRouteArgs.series(m.id));
            }
          },
        );
      },
    );
  }
}
