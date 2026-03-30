// lib/src/features/search/presentation/pages/provider_all_results_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';

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
  static const double _pageHorizontalPadding = 20;
  static const double _cardWidth = 150;
  static const double _posterHeight = 225;
  static const double _itemHeight = MoviMediaCard.listHeight;
  static const double _posterAspectRatio = _posterHeight / _cardWidth;
  static const double _cardChromeHeight = _itemHeight - _posterHeight;
  static const double _gridGapH = 24;
  static const double _gridGapV = 16;
  static const double _focusBleed = 12;
  static const double _minLargeCardWidth = 112;
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
    _profileSub = ref.listenManual<Profile?>(currentProfileProvider, (
      previous,
      next,
    ) {
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
    }, fireImmediately: false);

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

  ScreenType _screenTypeFor(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return ScreenTypeResolver.instance.resolve(size.width, size.height);
  }

  bool _isLargeScreen(BuildContext context) {
    final screenType = _screenTypeFor(context);
    return screenType == ScreenType.desktop || screenType == ScreenType.tv;
  }

  double _slotWidthFor(double availableWidth, int crossAxisCount) {
    return (availableWidth - (_gridGapH * (crossAxisCount - 1))) /
        crossAxisCount;
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
                onTimeout: () =>
                    throw TimeoutException('Timeout loading movies'),
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
          debugPrint(
            '[ProviderAllResultsPage] Only found ${collected.length} movies out of $targetNewItems requested for provider $providerId',
          );
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
                onTimeout: () =>
                    throw TimeoutException('Timeout loading shows'),
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
          debugPrint(
            '[ProviderAllResultsPage] Only found ${collected.length} shows out of $targetNewItems requested for provider $providerId',
          );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorTimeoutLoading)));
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
    return items
        .where((m) => allowedIds.contains(m.id.value))
        .toList(growable: false);
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
    return items
        .where((s) => allowedIds.contains(s.id.value))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == MoviMediaType.movie
        ? AppLocalizations.of(context)!.moviesTitle
        : AppLocalizations.of(context)!.seriesTitle;
    final itemsCount = widget.type == MoviMediaType.movie
        ? _movies.length
        : _shows.length;
    const backButtonFramePadding = 8.0;
    const backButtonSize = 35.0;
    final headerStartPadding =
        _pageHorizontalPadding - backButtonFramePadding;
    final trailingHeaderSpacerWidth = backButtonSize + backButtonFramePadding;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // Header avec bouton retour et titre centré
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                headerStartPadding,
                16,
                _pageHorizontalPadding,
                16,
              ),
              child: Row(
                children: [
                  MoviFocusableAction(
                    onPressed: () => context.pop(),
                    semanticLabel: 'Retour',
                    builder: (context, state) {
                      return MoviFocusFrame(
                        scale: state.focused ? 1.04 : 1,
                        padding: const EdgeInsets.all(backButtonFramePadding),
                        borderRadius: BorderRadius.circular(999),
                        backgroundColor: state.focused
                            ? Colors.white.withValues(alpha: 0.14)
                            : Colors.transparent,
                        child: SizedBox(
                          width: backButtonSize,
                          height: backButtonSize,
                          child: const MoviAssetIcon(
                            AppAssets.iconBack,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
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
                  SizedBox(width: trailingHeaderSpacerWidth),
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
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final availableWidth =
                            constraints.maxWidth - (_pageHorizontalPadding * 2);
                        final isLargeScreen = _isLargeScreen(context);
                        final baseLayoutCardWidth = _cardWidth + _focusBleed;
                        int crossAxisCount =
                            (availableWidth / (baseLayoutCardWidth + _gridGapH))
                                .floor()
                                .clamp(1, 6);

                        if (crossAxisCount < 1) {
                          crossAxisCount = 1;
                        } else if (crossAxisCount == 1 &&
                            availableWidth >= 300) {
                          crossAxisCount = 2;
                        }

                        if (isLargeScreen) {
                          crossAxisCount += 2;
                          while (crossAxisCount > 1 &&
                              (_slotWidthFor(availableWidth, crossAxisCount) -
                                      _focusBleed) <
                                  _minLargeCardWidth) {
                            crossAxisCount--;
                          }
                        }

                        final layoutCardWidth = _slotWidthFor(
                          availableWidth,
                          crossAxisCount,
                        );
                        final resolvedCardWidth = layoutCardWidth - _focusBleed;
                        final resolvedPosterHeight =
                            resolvedCardWidth * _posterAspectRatio;
                        final resolvedItemHeight =
                            resolvedPosterHeight + _cardChromeHeight;
                        final gridWidth =
                            (layoutCardWidth * crossAxisCount) +
                            _gridGapH * (crossAxisCount - 1);

                        return Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: _pageHorizontalPadding,
                            ),
                            child: SizedBox(
                              width: gridWidth,
                              child: GridView.builder(
                                controller: _scrollController,
                                padding: EdgeInsets.zero,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      childAspectRatio:
                                          layoutCardWidth /
                                          (resolvedItemHeight + _focusBleed),
                                      crossAxisSpacing: _gridGapH,
                                      mainAxisSpacing: _gridGapV,
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
                                    return Center(
                                      child: MoviMediaCard(
                                        media: media,
                                        width: resolvedCardWidth,
                                        height: resolvedPosterHeight,
                                        onTap: (mm) => navigateToMovieDetail(
                                          context,
                                          ref,
                                          ContentRouteArgs.movie(mm.id),
                                        ),
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
                                    return Center(
                                      child: MoviMediaCard(
                                        media: media,
                                        width: resolvedCardWidth,
                                        height: resolvedPosterHeight,
                                        onTap: (mm) => navigateToTvDetail(
                                          context,
                                          ref,
                                          ContentRouteArgs.series(mm.id),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
