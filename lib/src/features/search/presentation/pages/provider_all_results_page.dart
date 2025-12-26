// lib/src/features/search/presentation/pages/provider_all_results_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';

import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/utils/navigation_helpers.dart';
import 'package:movi/src/shared/presentation/router/content_route_args.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/features/search/presentation/models/provider_all_results_args.dart';
import 'package:movi/src/features/search/presentation/providers/search_providers.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

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
  ProviderSubscription<Profile?>? _profileSub;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Ensure parental filtering applies even if the current profile loads later
    // (ex: profiles fetched async).
    _profileSub = ref.listenManual<Profile?>(
      currentProfileProvider,
      (previous, next) {
        if (!mounted) return;
        final prevRestricted =
            previous != null && (previous.isKid || previous.pegiLimit != null);
        final nextRestricted =
            next != null && (next.isKid || next.pegiLimit != null);
        final changed =
            previous?.id != next?.id ||
            previous?.isKid != next?.isKid ||
            previous?.pegiLimit != next?.pegiLimit;

        if (changed || prevRestricted != nextRestricted) {
          // Reload from scratch so the list reflects the new restriction level.
          setState(() {
            _currentPage = 1;
            _hasMore = true;
            _movies.clear();
            _shows.clear();
          });
          unawaited(_loadMore());
        }
      },
      fireImmediately: false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadMore();
    });
  }

  @override
  void dispose() {
    _profileSub?.close();
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
      final profile = ref.read(currentProfileProvider);
      final bool hasRestrictions =
          profile != null && (profile.isKid || profile.pegiLimit != null);
      final int maxPrefetchPages = hasRestrictions ? 30 : 10;

      final useCase = ref.read(loadWatchProvidersUseCaseProvider);
      final providerId = widget.args.providerId;

      if (widget.type == MoviMediaType.movie) {
        const targetNewItems = 20;
        var tries = 0;
        var consecutiveEmptyPages = 0;
        final collected = <MovieSummary>[];

        while (_hasMore &&
            tries < maxPrefetchPages &&
            collected.length < targetNewItems) {
          final page = await useCase
              .getMovies(providerId, region: 'FR', page: _currentPage)
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () => throw TimeoutException('Timeout loading movies'),
              );
          final nextItems = await _filterMovies(page.items);
          
          // Détecter pages vides
          if (nextItems.isEmpty) {
            consecutiveEmptyPages++;
            // Arrêter si 3 pages vides consécutives ET on a essayé au moins 5 pages
            if (consecutiveEmptyPages >= 3 && tries >= 5) {
              break;
            }
          } else {
            consecutiveEmptyPages = 0; // Reset si on trouve des items
          }
          
          collected.addAll(nextItems);
          _hasMore = _currentPage < page.totalPages;
          _currentPage++;
          tries++;
        }
        
        // Log discret si le seuil n'est pas atteint mais qu'on a des résultats
        if (collected.length < targetNewItems && collected.isNotEmpty) {
          debugPrint('[ProviderAllResultsPage] Only found ${collected.length} movies out of $targetNewItems requested for provider $providerId');
        }

        if (!mounted) return;
        setState(() {
          _movies.addAll(collected);
          _isLoading = false;
        });
      } else {
        const targetNewItems = 20;
        var tries = 0;
        var consecutiveEmptyPages = 0;
        final collected = <TvShowSummary>[];

        while (_hasMore &&
            tries < maxPrefetchPages &&
            collected.length < targetNewItems) {
          final page = await useCase
              .getShows(providerId, region: 'FR', page: _currentPage)
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () => throw TimeoutException('Timeout loading shows'),
              );
          final nextItems = await _filterShows(page.items);
          
          // Détecter pages vides
          if (nextItems.isEmpty) {
            consecutiveEmptyPages++;
            // Arrêter si 3 pages vides consécutives ET on a essayé au moins 5 pages
            if (consecutiveEmptyPages >= 3 && tries >= 5) {
              break;
            }
          } else {
            consecutiveEmptyPages = 0; // Reset si on trouve des items
          }
          
          collected.addAll(nextItems);
          _hasMore = _currentPage < page.totalPages;
          _currentPage++;
          tries++;
        }
        
        // Log discret si le seuil n'est pas atteint mais qu'on a des résultats
        if (collected.length < targetNewItems && collected.isNotEmpty) {
          debugPrint('[ProviderAllResultsPage] Only found ${collected.length} shows out of $targetNewItems requested for provider $providerId');
        }

        if (!mounted) return;
        setState(() {
          _shows.addAll(collected);
          _isLoading = false;
        });
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasMore = false; // Arrêter les tentatives futures
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorTimeoutLoading)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        // Ne pas mettre _hasMore à false pour permettre une nouvelle tentative
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithMessage(e.toString()))),
        );
      }
    }
  }

  bool _hasRestrictions() {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return false;
    return profile.isKid || profile.pegiLimit != null;
  }

  Future<List<MovieSummary>> _filterMovies(List<MovieSummary> items) async {
    if (items.isEmpty) return items;
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return items;
    if (!_hasRestrictions()) return items;

    final policy = ref.read(parental.agePolicyProvider);
    final refs = items.map(
      (m) => ContentReference(
        id: m.id.value,
        type: ContentType.movie,
        title: m.title,
        poster: m.poster,
        year: m.releaseYear,
      ),
    );
    final allowed = await policy.filterAllowed(refs, profile);
    final allowedIds = allowed.map((r) => r.id).toSet();
    return items.where((m) => allowedIds.contains(m.id.value)).toList(growable: false);
  }

  Future<List<TvShowSummary>> _filterShows(List<TvShowSummary> items) async {
    if (items.isEmpty) return items;
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return items;
    if (!_hasRestrictions()) return items;

    final policy = ref.read(parental.agePolicyProvider);
    final refs = items.map(
      (s) => ContentReference(
        id: s.id.value,
        type: ContentType.series,
        title: s.title,
        poster: s.poster,
      ),
    );
    final allowed = await policy.filterAllowed(refs, profile);
    final allowedIds = allowed.map((r) => r.id).toSet();
    return items.where((s) => allowedIds.contains(s.id.value)).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == MoviMediaType.movie
        ? AppLocalizations.of(context)!.moviesTitle
        : AppLocalizations.of(context)!.seriesTitle;
    final itemsCount = widget.type == MoviMediaType.movie
        ? _movies.length
        : _shows.length;

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
                    child: SizedBox(
                      width: 35,
                      height: 35,
                      child: Image.asset(AppAssets.iconBack),
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
                  SizedBox(width: 35),
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
                                navigateToMovieDetail(
                                  context,
                                  ref,
                                  ContentRouteArgs.movie(mm.id),
                                ),
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
                            onTap: (mm) => navigateToTvDetail(
                              context,
                              ref,
                              ContentRouteArgs.series(mm.id),
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
