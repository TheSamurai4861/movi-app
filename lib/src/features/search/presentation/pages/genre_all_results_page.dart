// lib/src/features/search/presentation/pages/genre_all_results_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/presentation/focus_orchestrator_provider.dart';
import 'package:movi/src/core/focus/presentation/focus_region_scope.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/utils/navigation_helpers.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/shared/presentation/router/content_route_args.dart';
import 'package:movi/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart';
import 'package:movi/src/features/search/presentation/models/genre_all_results_args.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_detail_dto.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/core/parental/domain/services/genre_maturity_checker.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

/// Page affichant tous les résultats d'un genre avec pagination au scroll.
class GenreAllResultsPage extends ConsumerStatefulWidget {
  const GenreAllResultsPage({
    super.key,
    required this.args,
    required this.type,
  });

  final GenreAllResultsArgs args;
  final MoviMediaType type;

  @override
  ConsumerState<GenreAllResultsPage> createState() =>
      _GenreAllResultsPageState();
}

class _GenreAllResultsPageState extends ConsumerState<GenreAllResultsPage> {
  static const double _pageHorizontalPadding = 20;
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  int _loadRequestToken = 0;
  int _lastWheelLoadMs = 0;
  ProviderSubscription<Profile?>? _profileSub;
  final FocusNode _backFocusNode = FocusNode(debugLabel: 'GenreAllBack');
  final FocusNode _firstItemFocusNode = FocusNode(
    debugLabel: 'GenreAllFirstItem',
  );
  bool _didRequestInitialGridFocus = false;

  final List<TmdbMovieSummaryDto> _movies = [];
  final List<TmdbTvSummaryDto> _shows = [];

  bool get _isMovie => widget.type == MoviMediaType.movie;

  @override
  void initState() {
    super.initState();

    // Vérifier le genre avant de charger
    final profile = ref.read(currentProfileProvider);
    final profilePegi =
        parental.PegiRating.tryParse(profile?.pegiLimit)?.value ??
        (profile?.isKid == true ? 12 : null);

    if (profilePegi != null &&
        !GenreMaturityChecker.isGenreAllowed(
          widget.args.genreId,
          profilePegi,
        )) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ce genre n\'est pas disponible pour ce profil.'),
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop();
        }
      });
      return;
    }

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
        // Reload from scratch (pagination + filtering depend on the restriction level).
        setState(() {
          _resetPaginationAndInvalidateInFlight();
        });
        unawaited(_loadMore());
      }
    }, fireImmediately: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadMore());
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

    setState(() => _isLoading = true);

    try {
      final client = ref.read(slProvider)<TmdbClient>();
      final language = ref.read(asp.currentLanguageCodeProvider);

      final Profile? profile = ref.read(currentProfileProvider);
      final bool hasRestrictions =
          profile != null && (profile.isKid || profile.pegiLimit != null);
      final policy = hasRestrictions
          ? ref.read(parental.agePolicyProvider)
          : null;
      final json = await client
          .getJson(
            _isMovie ? 'discover/movie' : 'discover/tv',
            query: {
              'with_genres': widget.args.genreId.toString(),
              'page': _currentPage,
              'sort_by': 'popularity.desc',
            },
            language: language,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('Timeout loading results'),
          );
      if (!mounted || requestToken != _loadRequestToken) return;

      final results = (json['results'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      final totalPages = json['total_pages'] as int? ?? 1;

      if (_isMovie) {
        final nextMovies = results
            .map(TmdbMovieSummaryDto.fromJson)
            .toList(growable: false);
        final filteredMovies = hasRestrictions
            ? await _filterMovieDtos(
                policy: policy!,
                profile: profile,
                items: nextMovies,
              )
            : nextMovies;
        if (!mounted || requestToken != _loadRequestToken) return;
        setState(() {
          _movies.addAll(filteredMovies);
          _hasMore = _currentPage < totalPages;
          _currentPage++;
          _isLoading = false;
        });
      } else {
        final nextShows = results
            .map(TmdbTvSummaryDto.fromJson)
            .toList(growable: false);
        final filteredShows = hasRestrictions
            ? await _filterShowDtos(
                policy: policy!,
                profile: profile,
                items: nextShows,
              )
            : nextShows;
        if (!mounted || requestToken != _loadRequestToken) return;
        setState(() {
          _shows.addAll(filteredShows);
          _hasMore = _currentPage < totalPages;
          _currentPage++;
          _isLoading = false;
        });
      }
    } on TimeoutException {
      if (!mounted || requestToken != _loadRequestToken) return;
      setState(() {
        _isLoading = false;
        _hasMore = false;
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorTimeoutLoading)));
      }
    } catch (e) {
      if (!mounted || requestToken != _loadRequestToken) return;
      setState(() => _isLoading = false);
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
    _didRequestInitialGridFocus = false;
    _movies.clear();
    _shows.clear();
  }

  bool _enterRegion(
    AppFocusRegionId regionId, {
    bool restoreLastFocused = true,
  }) {
    return ref
        .read(focusOrchestratorProvider)
        .enterRegion(regionId, restoreLastFocused: restoreLastFocused);
  }

  bool _handleBack() {
    if (!context.mounted || !context.canPop()) {
      return false;
    }
    context.pop();
    return true;
  }

  KeyEventResult _handlePageBackKey(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      return _handleBack() ? KeyEventResult.handled : KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleHeaderKey(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _enterRegion(AppFocusRegionId.genreAllGrid, restoreLastFocused: false);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _requestInitialGridFocusIfNeeded(int count) {
    if (_didRequestInitialGridFocus || count == 0) {
      return;
    }
    _didRequestInitialGridFocus = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _enterRegion(AppFocusRegionId.genreAllGrid, restoreLastFocused: false);
    });
  }

  Future<List<TmdbMovieSummaryDto>> _filterMovieDtos({
    required parental.AgePolicy policy,
    required Profile profile,
    required List<TmdbMovieSummaryDto> items,
  }) async {
    if (items.isEmpty) return items;
    final refs = items.map(
      (m) => ContentReference(
        id: m.id.toString(),
        type: ContentType.movie,
        title: MediaTitle(m.title),
      ),
    );
    final allowed = await policy.filterAllowed(refs, profile);
    final allowedIds = allowed.map((r) => r.id).toSet();
    return items
        .where((m) => allowedIds.contains(m.id.toString()))
        .toList(growable: false);
  }

  Future<List<TmdbTvSummaryDto>> _filterShowDtos({
    required parental.AgePolicy policy,
    required Profile profile,
    required List<TmdbTvSummaryDto> items,
  }) async {
    if (items.isEmpty) return items;
    final refs = items.map(
      (s) => ContentReference(
        id: s.id.toString(),
        type: ContentType.series,
        title: MediaTitle(s.name),
      ),
    );
    final allowed = await policy.filterAllowed(refs, profile);
    final allowedIds = allowed.map((r) => r.id).toSet();
    return items
        .where((s) => allowedIds.contains(s.id.toString()))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageResolver = ref.read(slProvider)<TmdbImageResolver>();
    final count = _isMovie ? _movies.length : _shows.length;
    _requestInitialGridFocusIfNeeded(count);

    return FocusRegionScope(
      regionId: AppFocusRegionId.genreAllPrimary,
      binding: FocusRegionBinding(
        resolvePrimaryEntryNode: () =>
            count > 0 ? _firstItemFocusNode : _backFocusNode,
        resolveFallbackEntryNode: () => _backFocusNode,
      ),
      requestFocusOnMount: true,
      handleDirectionalExits: false,
      debugLabel: 'GenreAllResultsPrimary',
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (_, event) => _handlePageBackKey(event),
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          body: SafeArea(
            top: true,
            bottom: false,
            child: Column(
              children: [
                FocusRegionScope(
                  regionId: AppFocusRegionId.genreAllHeader,
                  binding: FocusRegionBinding(
                    resolvePrimaryEntryNode: () => _backFocusNode,
                  ),
                  handleDirectionalExits: false,
                  debugLabel: 'GenreAllResultsHeader',
                  child: Focus(
                    canRequestFocus: false,
                    skipTraversal: true,
                    onKeyEvent: (_, event) => _handleHeaderKey(event),
                    child: MoviSubpageBackTitleHeader(
                      title: widget.args.genreName,
                      onBack: _handleBack,
                      focusNode: _backFocusNode,
                      pageHorizontalPadding: _pageHorizontalPadding,
                    ),
                  ),
                ),
                Expanded(
                  child: count == 0 && !_isLoading
                      ? Center(
                          child: Text(
                            AppLocalizations.of(context)!.noResults,
                            style: const TextStyle(fontSize: 16),
                          ),
                        )
                      : FocusRegionScope(
                          regionId: AppFocusRegionId.genreAllGrid,
                          binding: FocusRegionBinding(
                            resolvePrimaryEntryNode: () => _firstItemFocusNode,
                            resolveFallbackEntryNode: () => _backFocusNode,
                          ),
                          handleDirectionalExits: false,
                          debugLabel: 'GenreAllResultsGrid',
                          child: ListView(
                            padding: const EdgeInsets.only(bottom: 24),
                            children: [
                              NotificationListener<ScrollNotification>(
                                onNotification: (notification) {
                                  if (!_hasMore || _isLoading) return false;
                                  if (notification
                                      is! ScrollUpdateNotification) {
                                    return false;
                                  }
                                  if (notification.dragDetails != null) {
                                    return false;
                                  }
                                  final delta = notification.scrollDelta;
                                  if (delta == null || delta <= 0) {
                                    return false;
                                  }
                                  if (notification.metrics.extentAfter > 320) {
                                    return false;
                                  }
                                  final now =
                                      DateTime.now().millisecondsSinceEpoch;
                                  if (now - _lastWheelLoadMs < 450) {
                                    return false;
                                  }
                                  _lastWheelLoadMs = now;
                                  unawaited(_loadMore());
                                  return false;
                                },
                                child: MoviMediaGrid(
                                  itemCount: count,
                                  firstItemFocusNode: _firstItemFocusNode,
                                  onExitUp: () => _enterRegion(
                                    AppFocusRegionId.genreAllHeader,
                                    restoreLastFocused: false,
                                  ),
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
                                        if (_isMovie) {
                                          final movie = _movies[index];
                                          final media = MoviMedia(
                                            id: movie.id.toString(),
                                            title: movie.title,
                                            poster: imageResolver.poster(
                                              movie.posterPath,
                                            ),
                                            year:
                                                movie.releaseDate != null &&
                                                    movie.releaseDate!.length >=
                                                        4
                                                ? int.tryParse(
                                                    movie.releaseDate!
                                                        .substring(0, 4),
                                                  )
                                                : null,
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
                                          title: show.name,
                                          poster: imageResolver.poster(
                                            show.posterPath,
                                          ),
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
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
