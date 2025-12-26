// lib/src/features/search/presentation/pages/genre_all_results_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/utils/app_assets.dart';
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
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  ProviderSubscription<Profile?>? _profileSub;

  final List<TmdbMovieSummaryDto> _movies = [];
  final List<TmdbTvSummaryDto> _shows = [];

  bool get _isMovie => widget.type == MoviMediaType.movie;

  @override
  void initState() {
    super.initState();
    
    // Vérifier le genre avant de charger
    final profile = ref.read(currentProfileProvider);
    final profilePegi = parental.PegiRating.tryParse(profile?.pegiLimit)?.value ??
        (profile?.isKid == true ? 12 : null);
    
    if (profilePegi != null &&
        !GenreMaturityChecker.isGenreAllowed(widget.args.genreId, profilePegi)) {
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
    
    _scrollController.addListener(_onScroll);
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
          // Reload from scratch (pagination + filtering depend on the restriction level).
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
      unawaited(_loadMore());
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
        unawaited(_loadMore());
      }
    }
  }

  static const double _cardWidth = 150;
  static const double _posterHeight = 225;
  static const double _textHeight =
      24; // hauteur approximative du titre (MoviMarqueeText: fontSize * 1.5)
  static const double _textMarginTop = 12; // marge entre affiche et texte
  static const double _gridGapH = 24; // gap horizontal
  static const double _gridGapV = 16; // gap vertical

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final client = ref.read(slProvider)<TmdbClient>();
      final language = ref.read(asp.currentLanguageCodeProvider);

      final Profile? profile = ref.read(currentProfileProvider);
      final bool hasRestrictions =
          profile != null && (profile.isKid || profile.pegiLimit != null);
      final int maxPrefetchPages = hasRestrictions ? 30 : 10;
      const targetNewItems = 20;
      final policy = hasRestrictions ? ref.read(parental.agePolicyProvider) : null;

      final collectedMovies = <TmdbMovieSummaryDto>[];
      final collectedShows = <TmdbTvSummaryDto>[];
      var tries = 0;
      var consecutiveEmptyPages = 0;

      while (_hasMore && tries < maxPrefetchPages) {
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

        final results = (json['results'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
        final totalPages = json['total_pages'] as int? ?? 1;

        if (_isMovie) {
          final nextMovies =
              results.map(TmdbMovieSummaryDto.fromJson).toList(growable: false);
          final filteredMovies = hasRestrictions
              ? await _filterMovieDtos(
                policy: policy!,
                profile: profile,
                items: nextMovies,
              )
              : nextMovies;
          
          // Détecter pages vides
          if (filteredMovies.isEmpty) {
            consecutiveEmptyPages++;
            // Arrêter si 3 pages vides consécutives ET on a essayé au moins 5 pages
            if (consecutiveEmptyPages >= 3 && tries >= 5) {
              break;
            }
          } else {
            consecutiveEmptyPages = 0; // Reset si on trouve des items
          }
          
          collectedMovies.addAll(filteredMovies);
        } else {
          final nextShows =
              results.map(TmdbTvSummaryDto.fromJson).toList(growable: false);
          final filteredShows = hasRestrictions
              ? await _filterShowDtos(
                policy: policy!,
                profile: profile,
                items: nextShows,
              )
              : nextShows;
          
          // Détecter pages vides
          if (filteredShows.isEmpty) {
            consecutiveEmptyPages++;
            // Arrêter si 3 pages vides consécutives ET on a essayé au moins 5 pages
            if (consecutiveEmptyPages >= 3 && tries >= 5) {
              break;
            }
          } else {
            consecutiveEmptyPages = 0; // Reset si on trouve des items
          }
          
          collectedShows.addAll(filteredShows);
        }

        _hasMore = _currentPage < totalPages;
        _currentPage++;
        tries++;

        final got = _isMovie ? collectedMovies.length : collectedShows.length;
        if (got >= targetNewItems) break;
        if (!_hasMore) break;
      }
      
      // Log discret si le seuil n'est pas atteint mais qu'on a des résultats
      final finalCount = _isMovie ? collectedMovies.length : collectedShows.length;
      if (finalCount < targetNewItems && finalCount > 0) {
        debugPrint('[GenreAllResultsPage] Only found $finalCount items out of $targetNewItems requested for genre ${widget.args.genreId}');
      }

      if (!mounted) return;
      setState(() {
        if (_isMovie) {
          _movies.addAll(collectedMovies);
        } else {
          _shows.addAll(collectedShows);
        }
        _isLoading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasMore = false;
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorTimeoutLoading)),
        );
      }
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
    return items.where((m) => allowedIds.contains(m.id.toString())).toList(growable: false);
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
    return items.where((s) => allowedIds.contains(s.id.toString())).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageResolver = ref.read(slProvider)<TmdbImageResolver>();
    final count = _isMovie ? _movies.length : _shows.length;
    final double itemHeight = _posterHeight + _textMarginTop + _textHeight;

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
                        widget.args.genreName,
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
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  int crossAxisCount =
                      (availableWidth / (_cardWidth + _gridGapH)).floor().clamp(
                        1,
                        6,
                      );
                  if (crossAxisCount < 1) {
                    crossAxisCount = 1;
                  } else if (crossAxisCount == 1 && availableWidth >= 300) {
                    crossAxisCount = 2;
                  }

                  final gridWidth =
                      (_cardWidth * crossAxisCount) +
                      _gridGapH * (crossAxisCount - 1);

                  return Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: gridWidth,
                      child: GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: _gridGapV,
                          crossAxisSpacing: _gridGapH,
                          childAspectRatio: _cardWidth / itemHeight,
                        ),
                        itemCount: count + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == count) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (_isMovie) {
                            final m = _movies[index];
                            final media = MoviMedia(
                              id: m.id.toString(),
                              title: m.title,
                              poster: imageResolver.poster(m.posterPath),
                              year:
                                  m.releaseDate != null &&
                                      m.releaseDate!.length >= 4
                                  ? int.tryParse(m.releaseDate!.substring(0, 4))
                                  : null,
                              type: MoviMediaType.movie,
                            );
                            return MoviMediaCard(
                              media: media,
                              onTap: (x) =>
                                  navigateToMovieDetail(
                                    context,
                                    ref,
                                    ContentRouteArgs.movie(x.id),
                                  ),
                              width: _cardWidth,
                              height: _posterHeight,
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
                              onTap: (x) => navigateToTvDetail(
                                context,
                                ref,
                                ContentRouteArgs.series(x.id),
                              ),
                              width: _cardWidth,
                              height: _posterHeight,
                            );
                          }
                        },
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
