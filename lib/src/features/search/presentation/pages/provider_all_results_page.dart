// lib/src/features/search/presentation/pages/provider_all_results_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';

import 'package:movi/src/core/models/models.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_detail_dto.dart';
import 'package:movi/src/features/search/presentation/models/provider_all_results_args.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;

/// Page affichant tous les résultats d'un provider avec pagination au scroll.
class ProviderAllResultsPage extends ConsumerStatefulWidget {
  const ProviderAllResultsPage({super.key, required this.args, required this.type});

  final ProviderAllResultsArgs args;
  final MoviMediaType type; // movie ou series

  @override
  ConsumerState<ProviderAllResultsPage> createState() => _ProviderAllResultsPageState();
}

class _ProviderAllResultsPageState extends ConsumerState<ProviderAllResultsPage> {
  int _currentPage = 1;
  final List<TmdbMovieSummaryDto> _movies = [];
  final List<TmdbTvSummaryDto> _shows = [];
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
      final client = ref.read(slProvider)<TmdbClient>();
      final language = ref.read(asp.currentLanguageCodeProvider);
      final providerId = widget.args.providerId;

      if (widget.type == MoviMediaType.movie) {
        final json = await client.getJson(
          'discover/movie',
          query: {
            'with_watch_providers': providerId.toString(),
            'watch_region': 'FR',
            'page': _currentPage,
          },
          language: language,
        );

        final results = (json['results'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map((e) => TmdbMovieSummaryDto.fromJson(e))
            .toList();

        final totalPages = json['total_pages'] as int? ?? 1;

        setState(() {
          _movies.addAll(results);
          _hasMore = _currentPage < totalPages;
          _currentPage++;
          _isLoading = false;
        });
      } else {
        final json = await client.getJson(
          'discover/tv',
          query: {
            'with_watch_providers': providerId.toString(),
            'watch_region': 'FR',
            'page': _currentPage,
          },
          language: language,
        );

        final results = (json['results'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map((e) => TmdbTvSummaryDto.fromJson(e))
            .toList();

        final totalPages = json['total_pages'] as int? ?? 1;

        setState(() {
          _shows.addAll(results);
          _hasMore = _currentPage < totalPages;
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
    final items = widget.type == MoviMediaType.movie ? _movies : _shows;
    final imageResolver = ref.read(slProvider)<TmdbImageResolver>();

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
                  SizedBox(
                    width: 35 + 8 + 50,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Grille avec pagination au scroll
            Expanded(
              child: items.isEmpty && !_isLoading
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context)!.noResults,
                        style: const TextStyle(fontSize: 16),
                      ),
                    )
                  : GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 150 / 270,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: items.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= items.length) {
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
                            title: m.title,
                            poster: imageResolver.poster(m.posterPath),
                            year: m.releaseDate != null && m.releaseDate!.isNotEmpty
                                ? (m.releaseDate!.length >= 4
                                    ? int.tryParse(m.releaseDate!.substring(0, 4))
                                    : null)
                                : null,
                            type: MoviMediaType.movie,
                          );
                          return MoviMediaCard(
                            media: media,
                            onTap: (mm) => context.push(
                              AppRouteNames.movie,
                              extra: mm,
                            ),
                          );
                        } else {
                          final s = _shows[index];
                          final media = MoviMedia(
                            id: s.id.toString(),
                            title: s.name,
                            poster: imageResolver.poster(s.posterPath),
                            type: MoviMediaType.series,
                          );
                          return MoviMediaCard(
                            media: media,
                            onTap: (mm) => context.push(
                              AppRouteNames.tv,
                              extra: mm,
                            ),
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

