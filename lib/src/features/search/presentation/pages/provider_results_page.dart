import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/focus/movi_focus_restore_policy.dart';
import 'package:movi/src/core/focus/movi_route_focus_boundary.dart';
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/utils/navigation_helpers.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart';
import 'package:movi/src/features/search/presentation/models/provider_all_results_args.dart';
import 'package:movi/src/features/search/presentation/models/provider_results_args.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_detail_dto.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/presentation/router/content_route_args.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';

class ProviderResultsPage extends ConsumerStatefulWidget {
  const ProviderResultsPage({super.key, this.args});

  final ProviderResultsArgs? args;

  @override
  ConsumerState<ProviderResultsPage> createState() =>
      _ProviderResultsPageState();
}

class _ProviderResultsPageState extends ConsumerState<ProviderResultsPage> {
  static const double _previewCardWidth = 150;
  static const double _previewPosterHeight = 225;
  static const double _previewRailItemHeight = 300;
  static const int _minPreviewItems = 10;
  static const int _maxPrefetchPagesDefault = 5;
  static const int _maxPrefetchPagesRestricted = 20;

  int _currentPageMovies = 1;
  int _currentPageShows = 1;
  final List<TmdbMovieSummaryDto> _movies = [];
  final List<TmdbTvSummaryDto> _shows = [];
  bool _isLoadingMovies = false;
  bool _isLoadingShows = false;
  bool _hasMoreMovies = true;
  bool _hasMoreShows = true;
  ProviderSubscription<Profile?>? _profileSub;
  bool _lastRestricted = false;
  final _backFocusNode = FocusNode(debugLabel: 'ProviderResultsBack');
  final _firstMovieFocusNode = FocusNode(
    debugLabel: 'ProviderResultsFirstMovie',
  );
  final _firstShowFocusNode = FocusNode(debugLabel: 'ProviderResultsFirstShow');
  final _moviesRetryFocusNode = FocusNode(
    debugLabel: 'ProviderResultsMoviesRetry',
  );
  final _showsRetryFocusNode = FocusNode(
    debugLabel: 'ProviderResultsShowsRetry',
  );
  bool _didRequestInitialMovieFocus = false;
  String? _moviesErrorMessage;
  String? _showsErrorMessage;

  bool _hasRestrictions(Profile? profile) =>
      profile != null && (profile.isKid || profile.pegiLimit != null);

  int _previewLimit(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenType = ScreenTypeResolver.instance.resolve(
      size.width,
      size.height,
    );
    return switch (screenType) {
      ScreenType.mobile => 10,
      ScreenType.tablet => 12,
      ScreenType.desktop => 16,
      ScreenType.tv => 18,
    };
  }

  @override
  void initState() {
    super.initState();
    if (widget.args == null) return;
    _profileSub = ref.listenManual<Profile?>(currentProfileProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;
      final restricted = _hasRestrictions(next);
      final previousRestricted = _hasRestrictions(previous);
      final changed =
          previous?.id != next?.id ||
          previous?.isKid != next?.isKid ||
          previous?.pegiLimit != next?.pegiLimit;
      if (!changed && restricted == previousRestricted) return;
      _lastRestricted = restricted;
      if (restricted) {
        unawaited(_applyParentalFilterToExisting(profile: next!));
      } else {
        unawaited(_loadMovies(loadMore: false));
        unawaited(_loadShows(loadMore: false));
      }
    }, fireImmediately: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadMovies();
      _loadShows();
    });
  }

  @override
  void dispose() {
    _profileSub?.close();
    _backFocusNode.dispose();
    _firstMovieFocusNode.dispose();
    _firstShowFocusNode.dispose();
    _moviesRetryFocusNode.dispose();
    _showsRetryFocusNode.dispose();
    super.dispose();
  }

  bool _handleBack(BuildContext context) {
    if (!context.mounted) return false;
    final navigator = Navigator.of(context);
    if (!navigator.canPop()) return false;
    navigator.maybePop();
    return true;
  }

  String? get _blockingErrorMessage =>
      _moviesErrorMessage ?? _showsErrorMessage;

  void _requestInitialMovieFocusIfNeeded(BuildContext context) {
    final screenType = ScreenTypeResolver.instance.resolve(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height,
    );
    if (screenType != ScreenType.tv ||
        _didRequestInitialMovieFocus ||
        _movies.isEmpty) {
      return;
    }
    _didRequestInitialMovieFocus = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _firstMovieFocusNode.context == null) return;
      _firstMovieFocusNode.requestFocus();
    });
  }

  void _openAllResults(MoviMediaType type) {
    final args = widget.args;
    if (args == null) return;
    context.push(
      AppRouteNames.providerAllResults,
      extra: ProviderAllResultsArgs(
        providerId: args.providerId,
        providerName: args.providerName,
        type: type,
      ),
    );
  }

  Widget _buildSeeAllProviderCard({
    required String title,
    required MoviMediaType type,
  }) {
    return SeeAllCard(
      title: title,
      width: _previewCardWidth,
      posterHeight: _previewPosterHeight,
      onTap: () => _openAllResults(type),
    );
  }

  Future<List<TmdbMovieSummaryDto>> _filterMovieDtos(
    List<TmdbMovieSummaryDto> items,
    Profile profile,
  ) async {
    if (items.isEmpty) return items;
    final policy = ref.read(parental.agePolicyProvider);
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

  Future<List<TmdbTvSummaryDto>> _filterShowDtos(
    List<TmdbTvSummaryDto> items,
    Profile profile,
  ) async {
    if (items.isEmpty) return items;
    final policy = ref.read(parental.agePolicyProvider);
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

  Future<List<TmdbMovieSummaryDto>> _fetchMoviesUntilFilled({
    required TmdbClient client,
    required String language,
    required int providerId,
    required Profile profile,
    required bool loadMore,
    required int minCount,
  }) async {
    final seen = <int>{for (final movie in _movies) movie.id};
    final collected = <TmdbMovieSummaryDto>[];
    var pagesTried = 0;
    var consecutiveEmptyPages = 0;
    final maxPages = _hasRestrictions(profile)
        ? _maxPrefetchPagesRestricted
        : _maxPrefetchPagesDefault;
    while (_hasMoreMovies && pagesTried < maxPages) {
      final json = await client.getJson(
        'discover/movie',
        query: {
          'with_watch_providers': providerId.toString(),
          'watch_region': 'FR',
          'page': _currentPageMovies,
        },
        language: language,
      );
      final resultsRaw = (json['results'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(TmdbMovieSummaryDto.fromJson)
          .where((movie) => !seen.contains(movie.id))
          .toList(growable: false);
      final totalPages = json['total_pages'] as int? ?? 1;
      _hasMoreMovies = _currentPageMovies < totalPages;
      _currentPageMovies++;
      pagesTried++;
      if (resultsRaw.isEmpty) {
        if (!_hasMoreMovies) break;
        continue;
      }
      for (final movie in resultsRaw) {
        seen.add(movie.id);
      }
      final filtered = await _filterMovieDtos(resultsRaw, profile);
      if (filtered.isEmpty) {
        consecutiveEmptyPages++;
        if (consecutiveEmptyPages >= 3 && pagesTried >= 5) break;
      } else {
        consecutiveEmptyPages = 0;
      }
      collected.addAll(filtered);
      final already = loadMore ? _movies.length : 0;
      if (already + collected.length >= minCount) break;
    }
    return collected;
  }

  Future<List<TmdbTvSummaryDto>> _fetchShowsUntilFilled({
    required TmdbClient client,
    required String language,
    required int providerId,
    required Profile profile,
    required bool loadMore,
    required int minCount,
  }) async {
    final seen = <int>{for (final show in _shows) show.id};
    final collected = <TmdbTvSummaryDto>[];
    var pagesTried = 0;
    var consecutiveEmptyPages = 0;
    final maxPages = _hasRestrictions(profile)
        ? _maxPrefetchPagesRestricted
        : _maxPrefetchPagesDefault;
    while (_hasMoreShows && pagesTried < maxPages) {
      final json = await client.getJson(
        'discover/tv',
        query: {
          'with_watch_providers': providerId.toString(),
          'watch_region': 'FR',
          'page': _currentPageShows,
        },
        language: language,
      );
      final resultsRaw = (json['results'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(TmdbTvSummaryDto.fromJson)
          .where((show) => !seen.contains(show.id))
          .toList(growable: false);
      final totalPages = json['total_pages'] as int? ?? 1;
      _hasMoreShows = _currentPageShows < totalPages;
      _currentPageShows++;
      pagesTried++;
      if (resultsRaw.isEmpty) {
        if (!_hasMoreShows) break;
        continue;
      }
      for (final show in resultsRaw) {
        seen.add(show.id);
      }
      final filtered = await _filterShowDtos(resultsRaw, profile);
      if (filtered.isEmpty) {
        consecutiveEmptyPages++;
        if (consecutiveEmptyPages >= 3 && pagesTried >= 5) break;
      } else {
        consecutiveEmptyPages = 0;
      }
      collected.addAll(filtered);
      final already = loadMore ? _shows.length : 0;
      if (already + collected.length >= minCount) break;
    }
    return collected;
  }

  Future<void> _applyParentalFilterToExisting({
    required Profile profile,
  }) async {
    if (!mounted || !_hasRestrictions(profile)) return;
    final filteredMovies = await _filterMovieDtos(_movies, profile);
    final filteredShows = await _filterShowDtos(_shows, profile);
    if (!mounted) return;
    setState(() {
      _movies
        ..clear()
        ..addAll(filteredMovies);
      _shows
        ..clear()
        ..addAll(filteredShows);
    });
  }

  Future<void> _loadMovies({bool loadMore = false}) async {
    if (_isLoadingMovies || !_hasMoreMovies || widget.args == null) return;
    setState(() {
      _isLoadingMovies = true;
      _moviesErrorMessage = null;
      if (!loadMore) {
        _currentPageMovies = 1;
        _movies.clear();
        _hasMoreMovies = true;
      }
    });
    try {
      final client = ref.read(slProvider)<TmdbClient>();
      final language = ref.read(asp.currentLanguageCodeProvider);
      final providerId = widget.args!.providerId;
      final profile = ref.read(currentProfileProvider);
      _lastRestricted = _hasRestrictions(profile);
      List<TmdbMovieSummaryDto> filtered;
      if (_lastRestricted && profile != null) {
        filtered = await _fetchMoviesUntilFilled(
          client: client,
          language: language,
          providerId: providerId,
          profile: profile,
          loadMore: loadMore,
          minCount: _minPreviewItems,
        );
      } else {
        final json = await client
            .getJson(
              'discover/movie',
              query: {
                'with_watch_providers': providerId.toString(),
                'watch_region': 'FR',
                'page': _currentPageMovies,
              },
              language: language,
            )
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () => throw TimeoutException('Timeout loading movies'),
            );
        final results = (json['results'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(TmdbMovieSummaryDto.fromJson)
            .toList();
        final totalPages = json['total_pages'] as int? ?? 1;
        _hasMoreMovies = _currentPageMovies < totalPages;
        _currentPageMovies++;
        filtered = results;
      }
      if (!mounted) return;
      setState(() {
        if (loadMore) {
          _movies.addAll(filtered);
        } else {
          _movies
            ..clear()
            ..addAll(filtered);
        }
        _isLoadingMovies = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isLoadingMovies = false;
        _moviesErrorMessage = l10n.errorTimeoutLoading;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isLoadingMovies = false;
        _moviesErrorMessage = l10n.errorWithMessage(e.toString());
      });
    }
  }

  Future<void> _loadShows({bool loadMore = false}) async {
    if (_isLoadingShows || !_hasMoreShows || widget.args == null) return;
    setState(() {
      _isLoadingShows = true;
      _showsErrorMessage = null;
      if (!loadMore) {
        _currentPageShows = 1;
        _shows.clear();
        _hasMoreShows = true;
      }
    });
    try {
      final client = ref.read(slProvider)<TmdbClient>();
      final language = ref.read(asp.currentLanguageCodeProvider);
      final providerId = widget.args!.providerId;
      final profile = ref.read(currentProfileProvider);
      _lastRestricted = _hasRestrictions(profile);
      List<TmdbTvSummaryDto> filtered;
      if (_lastRestricted && profile != null) {
        filtered = await _fetchShowsUntilFilled(
          client: client,
          language: language,
          providerId: providerId,
          profile: profile,
          loadMore: loadMore,
          minCount: _minPreviewItems,
        );
      } else {
        final json = await client
            .getJson(
              'discover/tv',
              query: {
                'with_watch_providers': providerId.toString(),
                'watch_region': 'FR',
                'page': _currentPageShows,
              },
              language: language,
            )
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () => throw TimeoutException('Timeout loading shows'),
            );
        final results = (json['results'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(TmdbTvSummaryDto.fromJson)
            .toList();
        final totalPages = json['total_pages'] as int? ?? 1;
        _hasMoreShows = _currentPageShows < totalPages;
        _currentPageShows++;
        filtered = results;
      }
      if (!mounted) return;
      setState(() {
        if (loadMore) {
          _shows.addAll(filtered);
        } else {
          _shows
            ..clear()
            ..addAll(filtered);
        }
        _isLoadingShows = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isLoadingShows = false;
        _showsErrorMessage = l10n.errorTimeoutLoading;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isLoadingShows = false;
        _showsErrorMessage = l10n.errorWithMessage(e.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.args == null) {
      final l10n = AppLocalizations.of(context)!;
      return NotFoundPage(
        message: l10n.notFoundWithEntity(l10n.entityProvider),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final providerName = widget.args!.providerName;
    final colorScheme = Theme.of(context).colorScheme;
    final previewLimit = _previewLimit(context);
    final moviesToShow = _movies.take(previewLimit).toList();
    final showsToShow = _shows.take(previewLimit).toList();
    const headerHorizontalPadding = 20.0;
    const backButtonFramePadding = 8.0;
    const backButtonSize = 35.0;
    final headerStartPadding = headerHorizontalPadding - backButtonFramePadding;
    final trailingHeaderSpacerWidth = backButtonSize + backButtonFramePadding;
    _requestInitialMovieFocusIfNeeded(context);

    final hasBlockingError =
        _movies.isEmpty &&
        _shows.isEmpty &&
        !_isLoadingMovies &&
        !_isLoadingShows &&
        _blockingErrorMessage != null;
    final initialFocusNode = hasBlockingError
        ? (_moviesErrorMessage != null
              ? _moviesRetryFocusNode
              : _showsRetryFocusNode)
        : _movies.isNotEmpty
        ? _firstMovieFocusNode
        : _shows.isNotEmpty
        ? _firstShowFocusNode
        : _backFocusNode;

    Widget buildMovieCard(TmdbMovieSummaryDto movie) {
      final imageResolver = ref.read(slProvider)<TmdbImageResolver>();
      final media = MoviMedia(
        id: movie.id.toString(),
        title: movie.title,
        poster: imageResolver.poster(movie.posterPath),
        year: movie.releaseDate != null && movie.releaseDate!.isNotEmpty
            ? (movie.releaseDate!.length >= 4
                  ? int.tryParse(movie.releaseDate!.substring(0, 4))
                  : null)
            : null,
        type: MoviMediaType.movie,
      );
      return MoviMediaCard(
        media: media,
        focusNode: identical(movie, moviesToShow.first)
            ? _firstMovieFocusNode
            : null,
        onTap: (selectedMedia) => navigateToMovieDetail(
          context,
          ref,
          ContentRouteArgs.movie(selectedMedia.id),
        ),
      );
    }

    Widget buildShowCard(TmdbTvSummaryDto show) {
      final imageResolver = ref.read(slProvider)<TmdbImageResolver>();
      final media = MoviMedia(
        id: show.id.toString(),
        title: show.name,
        poster: imageResolver.poster(show.posterPath),
        type: MoviMediaType.series,
      );
      return MoviMediaCard(
        media: media,
        focusNode: identical(show, showsToShow.first)
            ? _firstShowFocusNode
            : null,
        onTap: (selectedMedia) => navigateToTvDetail(
          context,
          ref,
          ContentRouteArgs.series(selectedMedia.id),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: MoviRouteFocusBoundary(
        restorePolicy: MoviFocusRestorePolicy(
          initialFocusNode: initialFocusNode,
          fallbackFocusNode: _backFocusNode,
        ),
        requestInitialFocusOnMount: true,
        onUnhandledBack: () => _handleBack(context),
        debugLabel: 'ProviderResultsRouteFocus',
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          body: SafeArea(
            top: true,
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    headerStartPadding,
                    16,
                    headerHorizontalPadding,
                    0,
                  ),
                  child: Row(
                    children: [
                      MoviFocusableAction(
                        focusNode: _backFocusNode,
                        onPressed: () => _handleBack(context),
                        semanticLabel: 'Retour',
                        builder: (context, state) {
                          return MoviFocusFrame(
                            scale: state.focused ? 1.04 : 1,
                            padding: const EdgeInsets.all(
                              backButtonFramePadding,
                            ),
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
                      SizedBox(width: trailingHeaderSpacerWidth),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: hasBlockingError
                      ? Center(
                          child: LaunchErrorPanel(
                            message: _blockingErrorMessage!,
                            retryLabel: l10n.actionRetry,
                            onRetry: () {
                              unawaited(_loadMovies());
                              unawaited(_loadShows());
                            },
                            retryFocusNode: _moviesErrorMessage != null
                                ? _moviesRetryFocusNode
                                : _showsRetryFocusNode,
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          children: [
                            if (_movies.isNotEmpty) ...[
                              MoviItemsList(
                                title: l10n.moviesTitle,
                                subtitle: _movies.length > previewLimit
                                    ? l10n.resultsCount(_movies.length)
                                    : null,
                                estimatedItemWidth: _previewCardWidth,
                                estimatedItemHeight: _previewRailItemHeight,
                                horizontalFocusAlignment: 0.18,
                                titlePadding: 20,
                                horizontalPadding:
                                    const EdgeInsetsDirectional.only(
                                      start: 20,
                                      end: 20,
                                    ),
                                items: [
                                  ...moviesToShow.map(buildMovieCard),
                                  if (_movies.length > previewLimit)
                                    _buildSeeAllProviderCard(
                                      title: l10n.moviesTitle,
                                      type: MoviMediaType.movie,
                                    ),
                                ],
                              ),
                            ] else if (!_isLoadingMovies &&
                                _moviesErrorMessage != null) ...[
                              _ProviderSectionError(
                                title: l10n.moviesTitle,
                                message: _moviesErrorMessage!,
                                retryLabel: l10n.actionRetry,
                                onRetry: () {
                                  unawaited(_loadMovies());
                                },
                                focusNode: _moviesRetryFocusNode,
                              ),
                            ],
                            if (_shows.isNotEmpty) ...[
                              MoviItemsList(
                                title: l10n.seriesTitle,
                                subtitle: _shows.length > previewLimit
                                    ? l10n.resultsCount(_shows.length)
                                    : null,
                                estimatedItemWidth: _previewCardWidth,
                                estimatedItemHeight: _previewRailItemHeight,
                                horizontalFocusAlignment: 0.18,
                                titlePadding: 20,
                                horizontalPadding:
                                    const EdgeInsetsDirectional.only(
                                      start: 20,
                                      end: 20,
                                    ),
                                items: [
                                  ...showsToShow.map(buildShowCard),
                                  if (_shows.length > previewLimit)
                                    _buildSeeAllProviderCard(
                                      title: l10n.seriesTitle,
                                      type: MoviMediaType.series,
                                    ),
                                ],
                              ),
                            ] else if (!_isLoadingShows &&
                                _showsErrorMessage != null) ...[
                              _ProviderSectionError(
                                title: l10n.seriesTitle,
                                message: _showsErrorMessage!,
                                retryLabel: l10n.actionRetry,
                                onRetry: () {
                                  unawaited(_loadShows());
                                },
                                focusNode: _showsRetryFocusNode,
                              ),
                            ],
                            if (_movies.isEmpty &&
                                _shows.isEmpty &&
                                !_isLoadingMovies &&
                                !_isLoadingShows &&
                                !hasBlockingError)
                              Center(
                                child: Text(
                                  l10n.noResults,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            if (_isLoadingMovies || _isLoadingShows)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
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

class _ProviderSectionError extends StatelessWidget {
  const _ProviderSectionError({
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    this.focusNode,
  });

  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
          ),
          const SizedBox(height: 12),
          Center(
            child: MoviPrimaryButton(
              label: retryLabel,
              onPressed: onRetry,
              focusNode: focusNode,
              expand: false,
            ),
          ),
        ],
      ),
    );
  }
}
