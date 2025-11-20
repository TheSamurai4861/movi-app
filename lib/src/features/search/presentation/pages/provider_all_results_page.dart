// lib/src/features/search/presentation/pages/provider_all_results_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';

import 'package:movi/src/core/models/models.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/features/search/presentation/models/provider_all_results_args.dart';
import 'package:movi/src/features/search/presentation/providers/search_providers.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';

/// Page affichant tous les résultats d'un provider avec pagination au scroll.
class ProviderAllResultsPage extends ConsumerStatefulWidget {
  const ProviderAllResultsPage({
    super.key,
    required this.args,
    required this.type,
  });

  final ProviderAllResultsArgs args;
  final MoviMediaType type; // movie ou series

  @override
  ConsumerState<ProviderAllResultsPage> createState() =>
      _ProviderAllResultsPageState();
}

class _ProviderAllResultsPageState
    extends ConsumerState<ProviderAllResultsPage> {
  int _currentPage = 1;
  final List<MovieSummary> _movies = [];
  final List<TvShowSummary> _shows = [];
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadMore();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoading && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final useCase = ref.read(loadWatchProvidersUseCaseProvider);
      final providerId = widget.args.providerId;

      if (widget.type == MoviMediaType.movie) {
        final page = await useCase.getMovies(
          providerId,
          region: 'FR',
          page: _currentPage,
        );

        if (!mounted) return;
        setState(() {
          _movies.addAll(page.items);
          _hasMore = _currentPage < page.totalPages;
          _currentPage++;
          _isLoading = false;
        });
      } else {
        final page = await useCase.getShows(
          providerId,
          region: 'FR',
          page: _currentPage,
        );

        if (!mounted) return;
        setState(() {
          _shows.addAll(page.items);
          _hasMore = _currentPage < page.totalPages;
          _currentPage++;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == MoviMediaType.movie
        ? AppLocalizations.of(context)!.moviesTitle
        : AppLocalizations.of(context)!.seriesTitle;
    final itemsCount = widget.type == MoviMediaType.movie ? _movies.length : _shows.length;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // Header avec bouton retour et titre centré
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.pop(),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 35,
                          height: 35,
                          child: Image.asset(AppAssets.iconBack),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.actionBack,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SizedBox(width: 35 + 8 + 50),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Grille avec pagination au scroll
            Expanded(
              child: itemsCount == 0 && !_isLoading
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context)!.noResults,
                        style: const TextStyle(fontSize: 16),
                      ),
                    )
                  : GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 150 / 270,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: itemsCount + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= itemsCount) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (widget.type == MoviMediaType.movie) {
                          final m = _movies[index];
                          final media = MoviMedia(
                            id: m.id.toString(),
                            title: m.title.value,
                            poster: m.poster,
                            year: m.releaseYear,
                            type: MoviMediaType.movie,
                          );
                          return MoviMediaCard(
                            media: media,
                            onTap: (mm) =>
                                context.push(AppRouteNames.movie, extra: mm),
                          );
                        } else {
                          final s = _shows[index];
                          final media = MoviMedia(
                            id: s.id.toString(),
                            title: s.title.value,
                            poster: s.poster,
                            type: MoviMediaType.series,
                          );
                          return MoviMediaCard(
                            media: media,
                            onTap: (mm) =>
                                context.push(AppRouteNames.tv, extra: mm),
                          );
                        }
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
