// lib/src/features/search/presentation/pages/provider_results_page.dart
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
import 'package:movi/src/features/search/presentation/models/provider_results_args.dart';
import 'package:movi/src/features/search/presentation/models/provider_all_results_args.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;

/// Page affichant les résultats filtrés par provider.
class ProviderResultsPage extends ConsumerStatefulWidget {
  const ProviderResultsPage({super.key, this.args});

  final ProviderResultsArgs? args;

  @override
  ConsumerState<ProviderResultsPage> createState() => _ProviderResultsPageState();
}

class _ProviderResultsPageState extends ConsumerState<ProviderResultsPage> {
  int _currentPageMovies = 1;
  int _currentPageShows = 1;
  final List<TmdbMovieSummaryDto> _movies = [];
  final List<TmdbTvSummaryDto> _shows = [];
  bool _isLoadingMovies = false;
  bool _isLoadingShows = false;
  bool _hasMoreMovies = true;
  bool _hasMoreShows = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.args != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadMovies();
        _loadShows();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMovies({bool loadMore = false}) async {
    if (_isLoadingMovies || !_hasMoreMovies) return;
    if (widget.args == null) return;

    setState(() {
      _isLoadingMovies = true;
      if (!loadMore) {
        _currentPageMovies = 1;
        _movies.clear();
      }
    });

    try {
      final client = ref.read(slProvider)<TmdbClient>();
      final language = ref.read(asp.currentLanguageCodeProvider);
      final providerId = widget.args!.providerId;

      final json = await client.getJson(
        'discover/movie',
        query: {
          'with_watch_providers': providerId.toString(),
          'watch_region': 'FR',
          'page': _currentPageMovies,
        },
        language: language,
      );

      final results = (json['results'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => TmdbMovieSummaryDto.fromJson(e))
          .toList();

      final totalPages = json['total_pages'] as int? ?? 1;

      setState(() {
        if (loadMore) {
          _movies.addAll(results);
        } else {
          _movies.clear();
          _movies.addAll(results);
        }
        _hasMoreMovies = _currentPageMovies < totalPages;
        _currentPageMovies++;
        _isLoadingMovies = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMovies = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  Future<void> _loadShows({bool loadMore = false}) async {
    if (_isLoadingShows || !_hasMoreShows) return;
    if (widget.args == null) return;

    setState(() {
      _isLoadingShows = true;
      if (!loadMore) {
        _currentPageShows = 1;
        _shows.clear();
      }
    });

    try {
      final client = ref.read(slProvider)<TmdbClient>();
      final language = ref.read(asp.currentLanguageCodeProvider);
      final providerId = widget.args!.providerId;

      final json = await client.getJson(
        'discover/tv',
        query: {
          'with_watch_providers': providerId.toString(),
          'watch_region': 'FR',
          'page': _currentPageShows,
        },
        language: language,
      );

      final results = (json['results'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => TmdbTvSummaryDto.fromJson(e))
          .toList();

      final totalPages = json['total_pages'] as int? ?? 1;

      setState(() {
        if (loadMore) {
          _shows.addAll(results);
        } else {
          _shows.clear();
          _shows.addAll(results);
        }
        _hasMoreShows = _currentPageShows < totalPages;
        _currentPageShows++;
        _isLoadingShows = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingShows = false;
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
    if (widget.args == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Provider inconnu')),
        body: const Center(child: Text('Provider introuvable')),
      );
    }

    final providerName = widget.args!.providerName;
    final colorScheme = Theme.of(context).colorScheme;
    final searchQuery = _searchController.text.toLowerCase().trim();
    
    // Filtrer les résultats par recherche
    final filteredMovies = searchQuery.isEmpty
        ? _movies
        : _movies.where((m) => m.title.toLowerCase().contains(searchQuery)).toList();
    final filteredShows = searchQuery.isEmpty
        ? _shows
        : _shows.where((s) => s.name.toLowerCase().contains(searchQuery)).toList();
    
    final moviesToShow = filteredMovies.take(10).toList();
    final showsToShow = filteredShows.take(10).toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
                        providerName,
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
                  // Espaceur pour équilibrer le bouton retour
                  SizedBox(
                    width: 35 + 8 + 50, // Largeur approximative du bouton retour
                  ),
                ],
              ),
            ),
            // Input de recherche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!
                      .providerSearchPlaceholder(providerName),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Image.asset(
                      AppAssets.iconSearch,
                      width: 25,
                      height: 25,
                    ),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Image.asset(
                            'assets/icons/supprimer.png',
                            width: 25,
                            height: 25,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          tooltip: AppLocalizations.of(context)!.clear,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Liste des films et séries
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                children: [
                  if (_movies.isNotEmpty) ...[
                    MoviItemsList(
                      title: AppLocalizations.of(context)!.moviesTitle,
                      subtitle: filteredMovies.length > 10
                          ? AppLocalizations.of(context)!
                              .resultsCount(filteredMovies.length)
                          : null,
                      estimatedItemWidth: 150,
                      estimatedItemHeight: 300,
                      titlePadding: 20,
                      horizontalPadding: const EdgeInsetsDirectional.only(
                        start: 20,
                        end: 20,
                      ),
                      action: filteredMovies.length > 10
                          ? TextButton(
                              onPressed: () {
                                // Naviguer vers la page "Voir tout" pour les films
                                context.push(
                                  AppRouteNames.providerAllResults,
                                  extra: ProviderAllResultsArgs(
                                    providerId: widget.args!.providerId,
                                    providerName: widget.args!.providerName,
                                    type: MoviMediaType.movie,
                                  ),
                                );
                              },
                              child: Text(
                                AppLocalizations.of(context)!.actionSeeAll,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : null,
                      items: moviesToShow
                          .map((m) {
                            final imageResolver =
                                ref.read(slProvider)<TmdbImageResolver>();
                            final media = MoviMedia(
                              id: m.id.toString(),
                              title: m.title,
                              poster: imageResolver.poster(m.posterPath),
                              year: m.releaseDate != null &&
                                      m.releaseDate!.isNotEmpty
                                  ? (m.releaseDate!.length >= 4
                                      ? int.tryParse(
                                          m.releaseDate!.substring(0, 4))
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
                          })
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_shows.isNotEmpty) ...[
                    MoviItemsList(
                      title: AppLocalizations.of(context)!.seriesTitle,
                      subtitle: filteredShows.length > 10
                          ? AppLocalizations.of(context)!
                              .resultsCount(filteredShows.length)
                          : null,
                      estimatedItemWidth: 150,
                      estimatedItemHeight: 300,
                      titlePadding: 20,
                      horizontalPadding: const EdgeInsetsDirectional.only(
                        start: 20,
                        end: 20,
                      ),
                      action: filteredShows.length > 10
                          ? TextButton(
                              onPressed: () {
                                // Naviguer vers la page "Voir tout" pour les séries
                                context.push(
                                  AppRouteNames.providerAllResults,
                                  extra: ProviderAllResultsArgs(
                                    providerId: widget.args!.providerId,
                                    providerName: widget.args!.providerName,
                                    type: MoviMediaType.series,
                                  ),
                                );
                              },
                              child: Text(
                                AppLocalizations.of(context)!.actionSeeAll,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : null,
                      items: showsToShow
                          .map((s) {
                            final imageResolver =
                                ref.read(slProvider)<TmdbImageResolver>();
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
                          })
                          .toList(growable: false),
                    ),
                  ],
                  if (filteredMovies.isEmpty &&
                      filteredShows.isEmpty &&
                      !_isLoadingMovies &&
                      !_isLoadingShows)
                    Center(
                      child: Text(
                        AppLocalizations.of(context)!.noResults,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  if (_isLoadingMovies || _isLoadingShows)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
