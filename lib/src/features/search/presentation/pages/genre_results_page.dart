// lib/src/features/search/presentation/pages/genre_results_page.dart
// ignore_for_file: unnecessary_import

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/router/not_found_page.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/utils/navigation_helpers.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/shared/presentation/router/content_route_args.dart';
import 'package:movi/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart';
import 'package:movi/src/features/search/presentation/models/genre_all_results_args.dart';
import 'package:movi/src/features/search/presentation/models/genre_results_args.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_detail_dto.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/core/parental/domain/services/genre_maturity_checker.dart';
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

class GenreResultsPage extends ConsumerStatefulWidget {
  const GenreResultsPage({super.key, this.args});

  final GenreResultsArgs? args;

  @override
  ConsumerState<GenreResultsPage> createState() => _GenreResultsPageState();
}

class _GenreResultsPageState extends ConsumerState<GenreResultsPage> {
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  final List<TmdbMovieSummaryDto> _movies = [];
  final List<TmdbTvSummaryDto> _shows = [];
  ProviderSubscription<Profile?>? _profileSub;

  bool get _isMovie => widget.args?.type == MoviMediaType.movie;

  @override
  void initState() {
    super.initState();

    // Vérifier le genre avant de charger
    if (widget.args != null) {
      final profile = ref.read(currentProfileProvider);
      final profilePegi =
          parental.PegiRating.tryParse(profile?.pegiLimit)?.value ??
          (profile?.isKid == true ? 12 : null);

      if (profilePegi != null &&
          !GenreMaturityChecker.isGenreAllowed(
            widget.args!.genreId,
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
        unawaited(_load(loadMore: false));
      }
    }, fireImmediately: false);
    if (widget.args != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_load(loadMore: false));
      });
    }
  }

  @override
  void dispose() {
    _profileSub?.close();
    super.dispose();
  }

  Future<void> _load({required bool loadMore}) async {
    if (_isLoading || !_hasMore) return;
    final args = widget.args;
    if (args == null) return;

    setState(() {
      _isLoading = true;
      if (!loadMore) {
        _currentPage = 1;
        _hasMore = true;
        _movies.clear();
        _shows.clear();
      }
    });

    try {
      final client = ref.read(slProvider)<TmdbClient>();
      final language = ref.read(asp.currentLanguageCodeProvider);
      final profile = ref.read(currentProfileProvider);
      final bool hasRestrictions =
          profile != null && (profile.isKid || profile.pegiLimit != null);
      final policy = hasRestrictions
          ? ref.read(parental.agePolicyProvider)
          : null;

      const desiredCount = 10;
      final maxPages = hasRestrictions ? 30 : 10;
      var tries = 0;
      var consecutiveEmptyPages = 0;

      var nextPage = _currentPage;
      var hasMore = _hasMore;

      final collectedMovies = <TmdbMovieSummaryDto>[];
      final collectedShows = <TmdbTvSummaryDto>[];

      while (hasMore && tries < maxPages) {
        final json = await client.getJson(
          _isMovie ? 'discover/movie' : 'discover/tv',
          query: {
            'with_genres': args.genreId.toString(),
            'page': nextPage,
            'sort_by': 'popularity.desc',
          },
          language: language,
        );

        final totalPages = json['total_pages'] as int? ?? 1;
        hasMore = nextPage < totalPages;
        nextPage++;
        tries++;

        final raw = (json['results'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);

        if (_isMovie) {
          final pageItems = raw
              .map(TmdbMovieSummaryDto.fromJson)
              .toList(growable: false);
          final filtered = (policy != null && profile != null)
              ? await _filterMovieDtos(
                  policy: policy,
                  profile: profile,
                  items: pageItems,
                )
              : pageItems;

          // Détecter pages vides
          if (filtered.isEmpty) {
            consecutiveEmptyPages++;
            // Arrêter si 3 pages vides consécutives ET on a essayé au moins 5 pages
            if (consecutiveEmptyPages >= 3 && tries >= 5) {
              break;
            }
          } else {
            consecutiveEmptyPages = 0; // Reset si on trouve des items
          }

          collectedMovies.addAll(filtered);
        } else {
          final pageItems = raw
              .map(TmdbTvSummaryDto.fromJson)
              .toList(growable: false);
          final filtered = (policy != null && profile != null)
              ? await _filterShowDtos(
                  policy: policy,
                  profile: profile,
                  items: pageItems,
                )
              : pageItems;

          // Détecter pages vides
          if (filtered.isEmpty) {
            consecutiveEmptyPages++;
            // Arrêter si 3 pages vides consécutives ET on a essayé au moins 5 pages
            if (consecutiveEmptyPages >= 3 && tries >= 5) {
              break;
            }
          } else {
            consecutiveEmptyPages = 0; // Reset si on trouve des items
          }

          collectedShows.addAll(filtered);
        }

        final count = _isMovie ? collectedMovies.length : collectedShows.length;
        if (count >= desiredCount) break;
        if (!hasMore) break;
      }

      // Log discret si le seuil n'est pas atteint mais qu'on a des résultats
      final finalCount = _isMovie
          ? collectedMovies.length
          : collectedShows.length;
      if (finalCount < desiredCount && finalCount > 0) {
        debugPrint(
          '[GenreResultsPage] Only found $finalCount items out of $desiredCount requested for genre ${args.genreId}',
        );
      }

      if (!mounted) return;
      setState(() {
        if (_isMovie) {
          _movies.addAll(collectedMovies);
        } else {
          _shows.addAll(collectedShows);
        }
        _currentPage = nextPage;
        _hasMore = hasMore;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithMessage(e.toString()))),
        );
      }
    }
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
    final args = widget.args;
    if (args == null) {
      final l10n = AppLocalizations.of(context)!;
      return NotFoundPage(message: l10n.notFoundWithEntity(l10n.entityGenre));
    }

    final colorScheme = Theme.of(context).colorScheme;
    final imageResolver = ref.read(slProvider)<TmdbImageResolver>();
    final itemCount = _isMovie ? _movies.length : _shows.length;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
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
                        args.genreName,
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
                  const SizedBox(width: 35 + 8 + 50),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  MoviItemsList(
                    title: _isMovie
                        ? AppLocalizations.of(context)!.moviesTitle
                        : AppLocalizations.of(context)!.seriesTitle,
                    subtitle: itemCount > 0
                        ? AppLocalizations.of(context)!.resultsCount(itemCount)
                        : null,
                    estimatedItemWidth: 150,
                    estimatedItemHeight: 300,
                    titlePadding: 20,
                    horizontalPadding: const EdgeInsetsDirectional.only(
                      start: 20,
                      end: 20,
                    ),
                    action: itemCount > 10
                        ? TextButton(
                            onPressed: () {
                              context.push(
                                AppRouteNames.genreAllResults,
                                extra: GenreAllResultsArgs(
                                  genreId: args.genreId,
                                  genreName: args.genreName,
                                  type: args.type,
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
                    items: _isMovie
                        ? _movies
                              .take(10)
                              .map((mm) {
                                final media = MoviMedia(
                                  id: mm.id.toString(),
                                  title: mm.title,
                                  poster: imageResolver.poster(mm.posterPath),
                                  year:
                                      mm.releaseDate != null &&
                                          mm.releaseDate!.length >= 4
                                      ? int.tryParse(
                                          mm.releaseDate!.substring(0, 4),
                                        )
                                      : null,
                                  type: MoviMediaType.movie,
                                );
                                return MoviMediaCard(
                                  media: media,
                                  onTap: (x) => navigateToMovieDetail(
                                    context,
                                    ref,
                                    ContentRouteArgs.movie(x.id),
                                  ),
                                );
                              })
                              .toList(growable: false)
                        : _shows
                              .take(10)
                              .map((ss) {
                                final media = MoviMedia(
                                  id: ss.id.toString(),
                                  title: ss.name,
                                  poster: imageResolver.poster(ss.posterPath),
                                  type: MoviMediaType.series,
                                );
                                return MoviMediaCard(
                                  media: media,
                                  onTap: (x) => navigateToTvDetail(
                                    context,
                                    ref,
                                    ContentRouteArgs.series(x.id),
                                  ),
                                );
                              })
                              .toList(growable: false),
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (!_isLoading && itemCount == 0)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          AppLocalizations.of(context)!.noResults,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
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
