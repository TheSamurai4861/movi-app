// lib/src/features/search/presentation/pages/search_results_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_spacing.dart';
import '../../../../core/widgets/movi_media_card.dart';
import '../../../../core/models/movi_media.dart';
import '../models/search_results_args.dart';
import '../providers/search_providers.dart';

class SearchResultsPage extends ConsumerWidget {
  const SearchResultsPage({super.key, this.args});

  final SearchResultsPageArgs? args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = args ?? const SearchResultsPageArgs(query: '', type: SearchResultsType.movies);
    final state = ref.watch(searchResultsControllerProvider(a));

    final title = state.type == SearchResultsType.movies ? 'Films' : 'Séries';
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
                  child: Text(state.error!, style: const TextStyle(color: Colors.red)),
                ),
              Expanded(
                child: _ResultsGrid(state: state),
              ),
              if (state.hasMore)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: ElevatedButton(
                    onPressed: () => ref.read(searchResultsControllerProvider(a).notifier).fetchNextPage(),
                    child: const Text('Charger plus'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultsGrid extends StatelessWidget {
  const _ResultsGrid({required this.state});

  final SearchResultsState state;

  @override
  Widget build(BuildContext context) {
    final items = state.type == SearchResultsType.movies
        ? state.itemsMovies.map((m) => MoviMedia(
              id: m.id.value,
              title: m.title.display,
              poster: m.poster.toString(),
              year: (m.releaseYear?.toString() ?? '—'),
              rating: '—',
              type: MoviMediaType.movie,
            ))
        : state.itemsShows.map((s) => MoviMedia(
              id: s.id.value,
              title: s.title.display,
              poster: s.poster.toString(),
              year: '—',
              rating: '—',
              type: MoviMediaType.series,
            ));

    final mediaList = items.toList(growable: false);

    if (mediaList.isEmpty) {
      return const Center(child: Text('Pas de résultats')); // fallback UI
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
        return MoviMediaCard(media: mediaList[index]);
      },
    );
  }
}