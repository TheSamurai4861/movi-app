// lib/src/features/search/presentation/pages/provider_all_results_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/focus/movi_focus_restore_policy.dart';
import 'package:movi/src/core/focus/movi_route_focus_boundary.dart';
import 'package:movi/l10n/app_localizations.dart';

import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/src/core/widgets/widgets.dart';
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
  int _currentPage = 1;
  final List<MovieSummary> _movies = [];
  final List<TvShowSummary> _shows = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _loadRequestToken = 0;
  int _lastWheelLoadMs = 0;
  ProviderSubscription<Profile?>? _profileSub;
  final FocusNode _backFocusNode = FocusNode(debugLabel: 'ProviderAllBack');
  final FocusNode _firstItemFocusNode = FocusNode(
    debugLabel: 'ProviderAllFirstItem',
  );

  @override
  void initState() {
    super.initState();

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
          _resetPaginationAndInvalidateInFlight();
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
    _backFocusNode.dispose();
    _firstItemFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    final requestToken = ++_loadRequestToken;

    setState(() {
      _isLoading = true;
    });

    try {
      final profile = ref.read(currentProfileProvider);
      final useCase = ref.read(loadWatchProvidersUseCaseProvider);
      final providerId = widget.args.providerId;

      if (widget.type == MoviMediaType.movie) {
        final page = await useCase
            .getMovies(providerId, region: 'FR', page: _currentPage)
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () => throw TimeoutException('Timeout loading movies'),
            );
        if (!mounted || requestToken != _loadRequestToken) return;
        final collected = await _filterMovies(page.items, profile: profile);
        if (!mounted || requestToken != _loadRequestToken) return;

        if (!mounted) return;
        setState(() {
          _movies.addAll(collected);
          _hasMore = _currentPage < page.totalPages;
          _currentPage++;
          _isLoading = false;
        });
      } else {
        final page = await useCase
            .getShows(providerId, region: 'FR', page: _currentPage)
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () => throw TimeoutException('Timeout loading shows'),
            );
        if (!mounted || requestToken != _loadRequestToken) return;
        final collected = await _filterShows(page.items, profile: profile);
        if (!mounted || requestToken != _loadRequestToken) return;

        if (!mounted) return;
        setState(() {
          _shows.addAll(collected);
          _hasMore = _currentPage < page.totalPages;
          _currentPage++;
          _isLoading = false;
        });
      }
    } on TimeoutException {
      if (!mounted || requestToken != _loadRequestToken) return;
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
      if (!mounted || requestToken != _loadRequestToken) return;
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

  void _resetPaginationAndInvalidateInFlight() {
    _loadRequestToken++;
    _currentPage = 1;
    _hasMore = true;
    _isLoading = false;
    _movies.clear();
    _shows.clear();
  }

  Future<List<MovieSummary>> _filterMovies(
    List<MovieSummary> items, {
    required Profile? profile,
  }) async {
    if (items.isEmpty) return items;
    final hasRestrictions =
        profile != null && (profile.isKid || profile.pegiLimit != null);
    if (!hasRestrictions) return items;

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

  Future<List<TvShowSummary>> _filterShows(
    List<TvShowSummary> items, {
    required Profile? profile,
  }) async {
    if (items.isEmpty) return items;
    final hasRestrictions =
        profile != null && (profile.isKid || profile.pegiLimit != null);
    if (!hasRestrictions) return items;

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
    final initialFocusNode = itemsCount > 0
        ? _firstItemFocusNode
        : _backFocusNode;

    return MoviRouteFocusBoundary(
      restorePolicy: MoviFocusRestorePolicy(
        initialFocusNode: initialFocusNode,
        fallbackFocusNode: _backFocusNode,
      ),
      requestInitialFocusOnMount: true,
      onUnhandledBack: () {
        if (!mounted) return false;
        Navigator.of(context).maybePop();
        return true;
      },
      debugLabel: 'ProviderAllResultsRouteFocus',
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          top: true,
          bottom: false,
          child: Column(
            children: [
              MoviSubpageBackTitleHeader(
                title: title,
                onBack: () => context.pop(),
                focusNode: _backFocusNode,
                pageHorizontalPadding: _pageHorizontalPadding,
              ),
              Expanded(
                child: itemsCount == 0 && !_isLoading
                    ? Center(
                        child: Text(
                          AppLocalizations.of(context)!.noResults,
                          style: const TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (!_hasMore || _isLoading) return false;
                              if (notification is! ScrollUpdateNotification) {
                                return false;
                              }
                              if (notification.dragDetails != null) {
                                return false;
                              }
                              final delta = notification.scrollDelta;
                              if (delta == null || delta <= 0) return false;
                              if (notification.metrics.extentAfter > 320) {
                                return false;
                              }
                              final now = DateTime.now().millisecondsSinceEpoch;
                              if (now - _lastWheelLoadMs < 450) return false;
                              _lastWheelLoadMs = now;
                              unawaited(_loadMore());
                              return false;
                            },
                            child: MoviMediaGrid(
                              itemCount: itemsCount,
                              firstItemFocusNode: _firstItemFocusNode,
                              onExitUp: () {
                                _backFocusNode.requestFocus();
                                return true;
                              },
                              onExitDown: () {
                                if (_hasMore && !_isLoading) {
                                  unawaited(_loadMore());
                                }
                                return true;
                              },
                              pageHorizontalPadding: _pageHorizontalPadding,
                              itemBuilder:
                                  (
                                    context,
                                    index,
                                    focusNode,
                                    cardWidth,
                                    posterHeight,
                                  ) {
                                    if (widget.type == MoviMediaType.movie) {
                                      final movie = _movies[index];
                                      final media = MoviMedia(
                                        id: movie.id.toString(),
                                        title: movie.title.value,
                                        poster: movie.poster,
                                        year: movie.releaseYear,
                                        type: MoviMediaType.movie,
                                      );
                                      return MoviMediaCard(
                                        media: media,
                                        width: cardWidth,
                                        height: posterHeight,
                                        focusNode: focusNode,
                                        onTap: (selectedMedia) =>
                                            navigateToMovieDetail(
                                              context,
                                              ref,
                                              ContentRouteArgs.movie(
                                                selectedMedia.id,
                                              ),
                                            ),
                                      );
                                    }

                                    final show = _shows[index];
                                    final media = MoviMedia(
                                      id: show.id.toString(),
                                      title: show.title.value,
                                      poster: show.poster,
                                      type: MoviMediaType.series,
                                    );
                                    return MoviMediaCard(
                                      media: media,
                                      width: cardWidth,
                                      height: posterHeight,
                                      focusNode: focusNode,
                                      onTap: (selectedMedia) =>
                                          navigateToTvDetail(
                                            context,
                                            ref,
                                            ContentRouteArgs.series(
                                              selectedMedia.id,
                                            ),
                                          ),
                                    );
                                  },
                            ),
                          ),
                          if (_isLoading) ...[
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
