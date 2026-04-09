// lib/src/features/search/presentation/pages/provider_results_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/focus/movi_focus_restore_policy.dart';
import 'package:movi/src/core/focus/movi_route_focus_boundary.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/core/utils/navigation_helpers.dart';

import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/src/shared/presentation/router/content_route_args.dart';
import 'package:movi/src/core/widgets/widgets.dart';
// ignore: unnecessary_import
import 'package:movi/src/core/router/not_found_page.dart';
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
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

/// Page affichant les résultats filtrés par provider.
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
  final FocusNode _backFocusNode = FocusNode(debugLabel: 'ProviderResultsBack');
  final FocusNode _firstMovieFocusNode = FocusNode(
    debugLabel: 'ProviderResultsFirstMovie',
  );
  final FocusNode _firstShowFocusNode = FocusNode(
    debugLabel: 'ProviderResultsFirstShow',
  );
  bool _didRequestInitialMovieFocus = false;

  bool _hasRestrictions(Profile? profile) =>
      profile != null && (profile.isKid || profile.pegiLimit != null);

  static const int _minPreviewItems = 10;
  // Augmenté pour les profils restreints (sera calculé dynamiquement)
  static const int _maxPrefetchPagesDefault = 5;
  static const int _maxPrefetchPagesRestricted = 20;

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
    if (widget.args != null) {
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

        // When switching profiles, ensure lists are aligned with restrictions:
        // - restricted => filter current lists and future loads
        // - unrestricted => reload full lists
        if (changed || restricted != previousRestricted) {
          _lastRestricted = restricted;
          if (restricted) {
            unawaited(_applyParentalFilterToExisting(profile: next!));
          } else {
            unawaited(_loadMovies(loadMore: false));
            unawaited(_loadShows(loadMore: false));
          }
        }
      }, fireImmediately: false);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadMovies();
        _loadShows();
      });
    }
  }

  @override
  void dispose() {
    _profileSub?.close();
    _backFocusNode.dispose();
    _firstMovieFocusNode.dispose();
    _firstShowFocusNode.dispose();
    super.dispose();
  }

  void _requestInitialMovieFocusIfNeeded(BuildContext context) {
    final screenType = ScreenTypeResolver.instance.resolve(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height,
    );
    if (screenType != ScreenType.tv) return;
    if (_didRequestInitialMovieFocus || _movies.isEmpty) return;
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
    final seen = <int>{for (final m in _movies) m.id};
    final collected = <TmdbMovieSummaryDto>[];
    var pagesTried = 0;
    var consecutiveEmptyPages = 0;

    final hasRestrictions = _hasRestrictions(profile);
    final maxPages = hasRestrictions
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
          .map((e) => TmdbMovieSummaryDto.fromJson(e))
          .where((m) => !seen.contains(m.id))
          .toList(growable: false);

      final totalPages = json['total_pages'] as int? ?? 1;
      _hasMoreMovies = _currentPageMovies < totalPages;
      _currentPageMovies++;
      pagesTried++;

      if (resultsRaw.isEmpty) {
        if (!_hasMoreMovies) break;
        continue;
      }

      for (final m in resultsRaw) {
        seen.add(m.id);
      }

      final filtered = await _filterMovieDtos(resultsRaw, profile);

      // Détecter pages vides après filtrage
      if (filtered.isEmpty) {
        consecutiveEmptyPages++;
        // Arrêter si 3 pages vides consécutives ET on a essayé au moins 5 pages
        if (consecutiveEmptyPages >= 3 && pagesTried >= 5) {
          break;
        }
      } else {
        consecutiveEmptyPages = 0; // Reset si on trouve des items
      }

      collected.addAll(filtered);

      final already = loadMore ? _movies.length : 0;
      if (already + collected.length >= minCount) break;
    }

    // Log discret si le seuil n'est pas atteint mais qu'on a des résultats
    final finalCount = loadMore
        ? _movies.length + collected.length
        : collected.length;
    if (finalCount < minCount && finalCount > 0) {
      debugPrint(
        '[ProviderResultsPage] Only found $finalCount movies out of $minCount requested for provider $providerId',
      );
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
    final seen = <int>{for (final s in _shows) s.id};
    final collected = <TmdbTvSummaryDto>[];
    var pagesTried = 0;
    var consecutiveEmptyPages = 0;

    final hasRestrictions = _hasRestrictions(profile);
    final maxPages = hasRestrictions
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
          .map((e) => TmdbTvSummaryDto.fromJson(e))
          .where((s) => !seen.contains(s.id))
          .toList(growable: false);

      final totalPages = json['total_pages'] as int? ?? 1;
      _hasMoreShows = _currentPageShows < totalPages;
      _currentPageShows++;
      pagesTried++;

      if (resultsRaw.isEmpty) {
        if (!_hasMoreShows) break;
        continue;
      }

      for (final s in resultsRaw) {
        seen.add(s.id);
      }

      final filtered = await _filterShowDtos(resultsRaw, profile);

      // Détecter pages vides après filtrage
      if (filtered.isEmpty) {
        consecutiveEmptyPages++;
        // Arrêter si 3 pages vides consécutives ET on a essayé au moins 5 pages
        if (consecutiveEmptyPages >= 3 && pagesTried >= 5) {
          break;
        }
      } else {
        consecutiveEmptyPages = 0; // Reset si on trouve des items
      }

      collected.addAll(filtered);

      final already = loadMore ? _shows.length : 0;
      if (already + collected.length >= minCount) break;
    }

    // Log discret si le seuil n'est pas atteint mais qu'on a des résultats
    final finalCount = loadMore
        ? _shows.length + collected.length
        : collected.length;
    if (finalCount < minCount && finalCount > 0) {
      debugPrint(
        '[ProviderResultsPage] Only found $finalCount shows out of $minCount requested for provider $providerId',
      );
    }

    return collected;
  }

  Future<void> _applyParentalFilterToExisting({
    required Profile profile,
  }) async {
    if (!mounted) return;
    if (!_hasRestrictions(profile)) return;

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
    if (_isLoadingMovies || !_hasMoreMovies) return;
    if (widget.args == null) return;

    setState(() {
      _isLoadingMovies = true;
      if (!loadMore) {
        _currentPageMovies = 1;
        _movies.clear();
        _hasMoreMovies =
            true; // Réinitialiser pour permettre un nouveau chargement
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
        // For kid/restricted profiles: keep fetching more pages until we have
        // enough allowed items to fill the preview.
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
            .map((e) => TmdbMovieSummaryDto.fromJson(e))
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
          _movies.clear();
          _movies.addAll(filtered);
        }
        _isLoadingMovies = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _isLoadingMovies = false;
        _hasMoreMovies = false; // Arrêter les tentatives futures
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
        _isLoadingMovies = false;
        // Ne pas mettre _hasMoreMovies à false pour permettre une nouvelle tentative
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithMessage(e.toString()))),
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
        _hasMoreShows = _currentPageShows < totalPages;
        _currentPageShows++;
        filtered = results;
      }

      setState(() {
        if (loadMore) {
          _shows.addAll(filtered);
        } else {
          _shows.clear();
          _shows.addAll(filtered);
        }
        _isLoadingShows = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingShows = false;
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithMessage(e.toString()))),
        );
      }
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

    final initialFocusNode = _movies.isNotEmpty
        ? _firstMovieFocusNode
        : _shows.isNotEmpty
        ? _firstShowFocusNode
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
      debugLabel: 'ProviderResultsRouteFocus',
      child: Scaffold(
      backgroundColor: colorScheme.surface,
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
                headerHorizontalPadding,
                0,
              ),
              child: Row(
                children: [
                  MoviFocusableAction(
                    focusNode: _backFocusNode,
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
                  SizedBox(width: trailingHeaderSpacerWidth),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Liste des films et séries
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                children: [
                  if (_movies.isNotEmpty) ...[
                    MoviItemsList(
                      title: AppLocalizations.of(context)!.moviesTitle,
                      subtitle: _movies.length > previewLimit
                          ? AppLocalizations.of(
                              context,
                            )!.resultsCount(_movies.length)
                          : null,
                      estimatedItemWidth: _previewCardWidth,
                      estimatedItemHeight: _previewRailItemHeight,
                      horizontalFocusAlignment: 0.18,
                      titlePadding: 20,
                      horizontalPadding: const EdgeInsetsDirectional.only(
                        start: 20,
                        end: 20,
                      ),
                      items: [
                        ...moviesToShow.map((m) {
                          final imageResolver = ref.read(
                            slProvider,
                          )<TmdbImageResolver>();
                          final media = MoviMedia(
                            id: m.id.toString(),
                            title: m.title,
                            poster: imageResolver.poster(m.posterPath),
                            year:
                                m.releaseDate != null &&
                                    m.releaseDate!.isNotEmpty
                                ? (m.releaseDate!.length >= 4
                                      ? int.tryParse(
                                          m.releaseDate!.substring(0, 4),
                                        )
                                      : null)
                                : null,
                            type: MoviMediaType.movie,
                          );
                          return MoviMediaCard(
                            media: media,
                            focusNode: identical(m, moviesToShow.first)
                                ? _firstMovieFocusNode
                                : null,
                            onTap: (mm) => navigateToMovieDetail(
                              context,
                              ref,
                              ContentRouteArgs.movie(mm.id),
                            ),
                          );
                        }),
                        if (_movies.length > previewLimit)
                          _buildSeeAllProviderCard(
                            title: AppLocalizations.of(context)!.moviesTitle,
                            type: MoviMediaType.movie,
                          ),
                      ],
                    ),
                  ],
                  if (_shows.isNotEmpty) ...[
                    MoviItemsList(
                      title: AppLocalizations.of(context)!.seriesTitle,
                      subtitle: _shows.length > previewLimit
                          ? AppLocalizations.of(
                              context,
                            )!.resultsCount(_shows.length)
                          : null,
                      estimatedItemWidth: _previewCardWidth,
                      estimatedItemHeight: _previewRailItemHeight,
                      horizontalFocusAlignment: 0.18,
                      titlePadding: 20,
                      horizontalPadding: const EdgeInsetsDirectional.only(
                        start: 20,
                        end: 20,
                      ),
                      items: [
                        ...showsToShow.map((s) {
                          final imageResolver = ref.read(
                            slProvider,
                          )<TmdbImageResolver>();
                          final media = MoviMedia(
                            id: s.id.toString(),
                            title: s.name,
                            poster: imageResolver.poster(s.posterPath),
                            type: MoviMediaType.series,
                          );
                          return MoviMediaCard(
                            media: media,
                            focusNode: identical(s, showsToShow.first)
                                ? _firstShowFocusNode
                                : null,
                            onTap: (mm) => navigateToTvDetail(
                              context,
                              ref,
                              ContentRouteArgs.series(mm.id),
                            ),
                          );
                        }),
                        if (_shows.length > previewLimit)
                          _buildSeeAllProviderCard(
                            title: AppLocalizations.of(context)!.seriesTitle,
                            type: MoviMediaType.series,
                          ),
                      ],
                    ),
                  ],
                  if (_movies.isEmpty &&
                      _shows.isEmpty &&
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
      ),)
    );
  }
}
