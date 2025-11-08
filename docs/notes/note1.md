import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class AppState extends Equatable {
  const AppState({
    this.themeMode = ThemeMode.system,
    this.isOnline = true,
    this.preferredLocale = 'en-US',
    this.activeIptvSources = const [],
  });

  final ThemeMode themeMode;
  final bool isOnline;
  final String preferredLocale;
  final List<String> activeIptvSources;

  AppState copyWith({
    ThemeMode? themeMode,
    bool? isOnline,
    String? preferredLocale,
    List<String>? activeIptvSources,
  }) {
    return AppState(
      themeMode: themeMode ?? this.themeMode,
      isOnline: isOnline ?? this.isOnline,
      preferredLocale: preferredLocale ?? this.preferredLocale,
      activeIptvSources: activeIptvSources ?? this.activeIptvSources,
    );
  }

  @override
  List<Object?> get props => [themeMode, isOnline, preferredLocale, activeIptvSources];
}


====

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'app_state.dart';

import '../preferences/locale_preferences.dart';

class AppStateController extends StateNotifier<AppState> {
  AppStateController(this._localePreferences)
      : super(AppState(preferredLocale: _localePreferences.languageCode));

  final LocalePreferences _localePreferences;

  // Safe read-only accessors for external services (avoid using protected `state`)
  List<String> get activeIptvSourceIds => List.unmodifiable(state.activeIptvSources);
  bool get hasActiveIptvSources => state.activeIptvSources.isNotEmpty;

  void setThemeMode(ThemeMode mode) {
    if (state.themeMode == mode) return;
    state = state.copyWith(themeMode: mode);
  }

  void setConnectivity(bool isOnline) {
    if (state.isOnline == isOnline) return;
    state = state.copyWith(isOnline: isOnline);
  }

  void setActiveIptvSources(List<String> sources) {
    state = state.copyWith(activeIptvSources: List.unmodifiable(sources));
  }

  Future<void> setPreferredLocale(String locale) async {
    if (state.preferredLocale == locale) return;
    await _localePreferences.setLanguageCode(locale);
    state = state.copyWith(preferredLocale: locale);
  }

  void addIptvSource(String accountId) {
    if (state.activeIptvSources.contains(accountId)) return;
    final updated = [...state.activeIptvSources, accountId];
    setActiveIptvSources(updated);
  }

  void removeIptvSource(String accountId) {
    if (!state.activeIptvSources.contains(accountId)) return;
    final updated = [...state.activeIptvSources]..remove(accountId);
    setActiveIptvSources(updated);
  }
}

=====

import 'package:flutter_riverpod/legacy.dart';

import '../di/injector.dart';
import 'app_state.dart';
import 'app_state_controller.dart';

final appStateControllerProvider = StateNotifierProvider<AppStateController, AppState>(
  (ref) => sl<AppStateController>(),
);

========

import 'package:equatable/equatable.dart';

import 'media_title.dart';

enum ContentType { movie, series, saga, playlist, person }

class ContentReference extends Equatable {
  const ContentReference({
    required this.id,
    required this.title,
    required this.type,
    this.poster,
    this.year,
    this.rating,
  });

  final String id;
  final MediaTitle title;
  final ContentType type;
  final Uri? poster;
  final int? year;
  final double? rating;

  @override
  List<Object?> get props => [id, title, type, poster];
}

=====

class MovieId {
  const MovieId(this.value);
  final String value;
  @override
  String toString() => value;
}

class SeriesId {
  const SeriesId(this.value);
  final String value;
  @override
  String toString() => value;
}

class EpisodeId {
  const EpisodeId(this.value);
  final String value;
  @override
  String toString() => value;
}

class SeasonId {
  const SeasonId(this.value);
  final String value;
  @override
  String toString() => value;
}

class PersonId {
  const PersonId(this.value);
  final String value;
  @override
  String toString() => value;
}

class SagaId {
  const SagaId(this.value);
  final String value;
  @override
  String toString() => value;
}

class PlaylistId {
  const PlaylistId(this.value);
  final String value;
  @override
  String toString() => value;
}

====

class MediaTitle {
  MediaTitle(String value)
      : value = value.trim();

  final String value;

  String get display => value;

  @override
  String toString() => value;
}

====

// lib/src/features/home/presentation/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/home_providers.dart' as hp;

import '../../../../core/utils/utils.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../../../core/widgets/movi_bottom_nav_bar.dart';
import '../../../../core/widgets/movi_items_list.dart';
import '../../../../core/widgets/movi_media_card.dart';
import '../../../../core/models/movi_media.dart';
import '../widgets/home_hero_section.dart';
import '../widgets/continue_watching_card.dart';
import '../../../../shared/domain/value_objects/content_reference.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _fadeDuration = Duration(milliseconds: 300);
  // Spec: bottom nav 24px from bottom edge
  static const _navBottomOffset = 24.0;

  int _selectedIndex = 0;

  void _handleNavTap(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final navHeight = moviNavBarHeight();
    final bottomPadding = navHeight + _navBottomOffset + media.padding.bottom;

    final pages = <Widget>[
      const _HomeContent(),
      _NavPlaceholder(title: 'Recherche', bottomPadding: bottomPadding),
      _NavPlaceholder(title: 'Bibliothèque', bottomPadding: bottomPadding),
      _NavPlaceholder(title: 'Paramètres', bottomPadding: bottomPadding),
    ];

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: _fadeDuration,
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: pages[_selectedIndex],
            ),
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: _navBottomOffset + media.padding.bottom,
              child: MoviBottomNavBar(
                selectedIndex: _selectedIndex,
                onItemSelected: _handleNavTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  static const double _mediaCardWidth = 150; // doit rester aligné avec MoviMediaCard par défaut
  static const double _itemSpacing = 32;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(hp.homeControllerProvider);
        final controller = ref.read(hp.homeControllerProvider.notifier);

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: CustomScrollView(
            slivers: [
              if (state.error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Une erreur est survenue. Balayez vers le bas pour réessayer.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Hero section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: HomeHeroSection(
                    movie: state.hero.isNotEmpty ? state.hero.first : null,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 54)),

              if (state.cwMovies.isNotEmpty || state.cwShows.isNotEmpty)
                SliverToBoxAdapter(
                  child: MoviItemsList(
                    title: 'En cours',
                    itemSpacing: _itemSpacing,
                    estimatedItemWidth: _mediaCardWidth,
                    // Pas d’enrichissement pour “En cours” (local-only), donc pas de callback.
                    items: [
                      ...state.cwMovies.map(
                        (m) => ContinueWatchingCard.movie(
                          title: m.title.value,
                          poster: (m.backdrop ?? m.poster).toString(),
                          year: m.releaseYear?.toString() ?? '—',
                          progress: 0,
                          onTap: () => context.push('/movie'),
                        ),
                      ),
                      ...state.cwShows.map(
                        (s) => ContinueWatchingCard.episode(
                          title: s.title.value,
                          seriesTitle: s.title.value,
                          poster: (s.backdrop ?? s.poster).toString(),
                          seasonEpisode: 'S?? E??',
                          progress: 0,
                          onTap: () => context.push('/tv'),
                        ),
                      ),
                    ],
                  ),
                ),

              if (state.iptvLists.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Text(
                      'Aucune source IPTV active. Ajoutez une source dans Paramètres pour voir vos catégories.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),

              // Sections IPTV — enrichissement à la volée sur scroll horizontal
              for (final entry in state.iptvLists.entries)
                SliverToBoxAdapter(
                  child: MoviItemsList(
                    title: entry.key,
                    itemSpacing: _itemSpacing,
                    estimatedItemWidth: _mediaCardWidth,
                    // → Notifie le contrôleur pour enrichir le batch visible (+preload).
                    onViewportChanged: (start, count) {
                      controller.enrichCategoryBatch(entry.key, start, count);
                    },
                    items: entry.value.take(40).map((r) {
                      final media = MoviMedia(
                        id: r.id,
                        title: r.title.value,
                        poster: r.poster?.toString() ?? '',
                        year: r.year?.toString() ?? '—',
                        rating: (r.rating != null)
                            ? (r.rating! >= 10 ? '10' : r.rating!.toStringAsFixed(1))
                            : '—',
                        type: r.type == ContentType.series
                            ? MoviMediaType.series
                            : MoviMediaType.movie,
                      );
                      return MoviMediaCard(media: media);
                    }).toList(),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }
}

class _NavPlaceholder extends StatelessWidget {
  const _NavPlaceholder({required this.title, required this.bottomPadding});

  final String title;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        bottomPadding,
      ),
      child: Center(
        child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}


========

// lib/src/features/home/presentation/widgets/home_hero_section.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/utils/app_assets.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../../../core/widgets/movi_favorite_button.dart';
import '../../../../core/widgets/movi_pill.dart';
import '../../../../core/widgets/movi_primary_button.dart';
import '../../../movie/domain/entities/movie_summary.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/data/services/tmdb_cache_data_source.dart';
import '../../../../shared/data/services/tmdb_image_resolver.dart';

class HomeHeroSection extends StatefulWidget {
  const HomeHeroSection({super.key, required this.movie});
  final MovieSummary? movie;

  @override
  State<HomeHeroSection> createState() => _HomeHeroSectionState();
}

class _HomeHeroSectionState extends State<HomeHeroSection> {
  bool _favorite = false;

  late final TmdbCacheDataSource _cache = sl<TmdbCacheDataSource>();
  late final TmdbImageResolver _images = sl<TmdbImageResolver>();

  Future<_HeroMeta?> _loadMeta(MovieSummary m) async {
    // On essaie d’enrichir depuis le cache TMDB (pas d’appel réseau ici).
    // Si pas trouvé, on retourne juste null et on garde les fallbacks.
    if (m.tmdbId == null) return null;

    final data = await _cache.getMovieDetail(m.tmdbId!);
    if (data == null) return null;

    final imagesMap = (data['images'] as Map<String, dynamic>?) ?? const {};
    final posters = (imagesMap['posters'] as List<dynamic>? ?? const []);
    final logos = (imagesMap['logos'] as List<dynamic>? ?? const []);

    final posterNoLangPath = _selectPosterNoLang(posters) ?? data['poster_path']?.toString();
    final logoPath = _selectLogoFrEnNoLang(logos);

    final poster = _images.poster(posterNoLangPath);
    final backdrop = _images.backdrop(data['backdrop_path']?.toString());
    final overview = (data['overview']?.toString() ?? '').trim();
    final vote = (data['vote_average'] as num?)?.toDouble();
    final year = _parseYear(data['release_date']?.toString());

    return _HeroMeta(
      poster: poster,
      backdrop: backdrop,
      logo: _images.logo(logoPath),
      overview: overview.isEmpty ? null : overview,
      year: year,
      rating: vote,
    );
  }

  /// Choisit un poster **sans langue** prioritairement, sinon EN, sinon meilleur score.
  String? _selectPosterNoLang(List<dynamic> posters) {
    if (posters.isEmpty) return null;
    String? pathOf(Map<String, dynamic> m) => m['file_path']?.toString();
    num scoreOf(Map<String, dynamic> m) => (m['vote_average'] as num?) ?? 0;

    final list = posters.cast<Map<String, dynamic>>();

    final noLang = list.where((m) => m['iso_639_1'] == null).toList()
      ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (noLang.isNotEmpty) return pathOf(noLang.first);

    final en = list.where((m) => (m['iso_639_1']?.toString().toLowerCase() == 'en')).toList()
      ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (en.isNotEmpty) return pathOf(en.first);

    list.sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    return pathOf(list.first);
  }

  /// Choisit un logo **FR → EN → sans langue → meilleur score**.
  String? _selectLogoFrEnNoLang(List<dynamic> logos) {
    if (logos.isEmpty) return null;
    String? pathOf(Map<String, dynamic> m) => m['file_path']?.toString();
    num scoreOf(Map<String, dynamic> m) => (m['vote_average'] as num?) ?? 0;

    final list = logos.cast<Map<String, dynamic>>();

    final fr = list.where((m) => (m['iso_639_1']?.toString().toLowerCase() == 'fr')).toList()
      ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (fr.isNotEmpty) return pathOf(fr.first);

    final en = list.where((m) => (m['iso_639_1']?.toString().toLowerCase() == 'en')).toList()
      ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (en.isNotEmpty) return pathOf(en.first);

    final noLang = list.where((m) => m['iso_639_1'] == null).toList()
      ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (noLang.isNotEmpty) return pathOf(noLang.first);

    list.sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    return pathOf(list.first);
  }

  int? _parseYear(String? raw) =>
      (raw != null && raw.isNotEmpty) ? int.tryParse(raw.substring(0, 4)) : null;

  @override
  Widget build(BuildContext context) {
    // Spéc : hauteur totale 690, on évite l’overflow en laissant l’image s’étirer.
    const double totalHeight = 690;
    const double overlayHeight = 125;

    final movie = widget.movie;

    return SizedBox(
      height: totalHeight,
      width: double.infinity,
      child: movie == null
          ? _HeroSkeleton(overlayHeight: overlayHeight)
          : FutureBuilder<_HeroMeta?>(
              future: _loadMeta(movie),
              builder: (context, snap) {
                final meta = snap.data;

                final posterUri = meta?.poster ?? (movie.backdrop ?? movie.poster);
                final hasLogo = meta?.logo != null;
                final showYear = (meta?.year ?? movie.releaseYear) != null;
                final yearText =
                    (meta?.year ?? movie.releaseYear)?.toString() ?? '—';
                final ratingText = meta?.rating != null
                    ? meta!.rating!.toStringAsFixed(meta.rating! >= 10 ? 0 : 1)
                    : null;
                final hasSynopsis = (meta?.overview != null && meta!.overview!.isNotEmpty);

                Widget buildPoster() {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      posterUri.toString(),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF222222),
                      ),
                    ),
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Image occupe l’espace restant → pas d’overflow
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          buildPoster(),

                          // Overlays bas
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              height: overlayHeight,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Color(0xFF141414), Color(0x00141414)],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              height: overlayHeight,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Color(0xFF141414), Color(0x00141414)],
                                ),
                              ),
                            ),
                          ),

                          // Logo (FR→EN→no-lang) sinon titre
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: overlayHeight - 100,
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 100),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg),
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: hasLogo
                                        ? Image.network(
                                            meta!.logo.toString(),
                                            height: 100,
                                            errorBuilder: (_, __, ___) =>
                                                _TitleFallback(movie.title.value),
                                          )
                                        : _TitleFallback(movie.title.value),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Pills : année + (note si dispo)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (showYear) MoviPill(yearText, large: true),
                        if (showYear && ratingText != null) const SizedBox(width: 8),
                        if (ratingText != null) MoviPill(ratingText, large: true),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Synopsis si disponible
                    if (hasSynopsis)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Text(
                          meta.overview!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    if (hasSynopsis) const SizedBox(height: 16),

                    // Actions
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: MoviPrimaryButton(
                              label: 'Regarder maintenant',
                              assetIcon: AppAssets.iconPlay,
                              onPressed: () => context.push(AppRouteNames.movie),
                            ),
                          ),
                          const SizedBox(width: 16),
                          MoviFavoriteButton(
                            isFavorite: _favorite,
                            onPressed: () =>
                                setState(() => _favorite = !_favorite),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
    );
  }
}

class _TitleFallback extends StatelessWidget {
  const _TitleFallback(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _HeroMeta {
  const _HeroMeta({
    this.poster,
    this.backdrop,
    this.logo,
    this.overview,
    this.year,
    this.rating,
  });

  final Uri? poster;
  final Uri? backdrop;
  final Uri? logo;
  final String? overview;
  final int? year;
  final double? rating;
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton({required this.overlayHeight});
  final double overlayHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // zone image
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(color: const Color(0xFF222222)),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: overlayHeight,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xFF141414), Color(0x00141414)],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: overlayHeight - 100,
                child: Center(
                  child: Image.asset(AppAssets.iconAppLogo, height: 100),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: const [
              Expanded(
                child: SizedBox(height: 48),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}


import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/di/injector.dart';
import '../../../movie/domain/entities/movie_summary.dart';
import '../../../tv/domain/entities/tv_show.dart';
import '../../../../shared/domain/value_objects/content_reference.dart';
import '../../domain/repositories/home_feed_repository.dart';

class HomeState {
  const HomeState({
    this.hero = const [],
    this.cwMovies = const [],
    this.cwShows = const [],
    this.iptvLists = const {},
    this.isLoading = false,
    this.error,
  });

  final List<MovieSummary> hero;
  final List<MovieSummary> cwMovies;
  final List<TvShowSummary> cwShows;
  final Map<String, List<ContentReference>> iptvLists;
  final bool isLoading;
  final String? error;

  HomeState copyWith({
    List<MovieSummary>? hero,
    List<MovieSummary>? cwMovies,
    List<TvShowSummary>? cwShows,
    Map<String, List<ContentReference>>? iptvLists,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      hero: hero ?? this.hero,
      cwMovies: cwMovies ?? this.cwMovies,
      cwShows: cwShows ?? this.cwShows,
      iptvLists: iptvLists ?? this.iptvLists,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class HomeController extends StateNotifier<HomeState> {
  HomeController(this._repo) : super(const HomeState());

  final HomeFeedRepository _repo;

  /// Empêche de relancer l’enrichissement pour les mêmes cartes en parallèle.
  /// Clé = "sectionKey#index"
  final Set<String> _inflight = {};

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final heroF = _repo.getHeroMovies();
      final cwMoviesF = _repo.getContinueWatchingMovies();
      final cwShowsF = _repo.getContinueWatchingShows();
      final iptvF = _repo.getIptvCategoryLists();

      final results = await Future.wait([heroF, cwMoviesF, cwShowsF, iptvF]);

      state = state.copyWith(
        hero: results[0] as List<MovieSummary>,
        cwMovies: results[1] as List<MovieSummary>,
        cwShows: results[2] as List<TvShowSummary>,
        iptvLists: results[3] as Map<String, List<ContentReference>>,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
    }
  }

  Future<void> refresh() => load();

  /// Appelée par l’UI quand une section horizontale fait défiler des cartes.
  /// Enrichit les items [start .. start+count-1] s'ils sont encore “légers”.
  Future<void> enrichCategoryBatch(String key, int start, int count) async {
    final list = state.iptvLists[key];
    if (list == null || list.isEmpty) return;
    if (start < 0 || count <= 0) return;

    final end = (start + count - 1).clamp(0, list.length - 1);

    for (int i = start; i <= end; i++) {
      final ref = list[i];

      // Heuristique "léger" : pas d'année ou pas de note ou pas de poster TMDB
      final needsEnrich = ref.year == null ||
          ref.rating == null ||
          ref.poster == null ||
          // Si poster existe mais n'est pas un visuel TMDB (souvent IPTV)
          !(ref.poster.toString().contains('image.tmdb.org'));

      if (!needsEnrich) continue;

      final keyIndex = '$key#$i';
      if (_inflight.contains(keyIndex)) continue;
      _inflight.add(keyIndex);

      unawaited(
        _repo.enrichReference(ref).then((enriched) {
          _inflight.remove(keyIndex);
          // Remplacement immuable dans l’état
          final current = state.iptvLists[key];
          if (current == null || i >= current.length) return;

          final nextList = List<ContentReference>.from(current);
          nextList[i] = enriched;

          final nextMap = Map<String, List<ContentReference>>.from(state.iptvLists);
          nextMap[key] = nextList;

          state = state.copyWith(iptvLists: nextMap);
        }).catchError((_) {
          _inflight.remove(keyIndex);
        }),
      );
    }
  }
}

final homeFeedRepositoryProvider =
    Provider<HomeFeedRepository>((ref) => sl<HomeFeedRepository>());

final homeControllerProvider =
    StateNotifierProvider<HomeController, HomeState>(
  (ref) => HomeController(ref.read(homeFeedRepositoryProvider))..load(),
);


// lib/src/features/home/data/repositories/home_feed_repository_impl.dart
import 'package:movi/src/core/di/injector.dart';
import 'package:movi/src/core/iptv/domain/entities/xtream_playlist_item.dart';

import '../../../movie/domain/entities/movie_summary.dart';
import '../../../movie/domain/repositories/movie_repository.dart';
import '../../../movie/data/datasources/tmdb_movie_remote_data_source.dart';
import '../../../tv/domain/entities/tv_show.dart';
import '../../../tv/domain/repositories/tv_repository.dart';
import '../../../tv/data/datasources/tmdb_tv_remote_data_source.dart';
import '../../../../shared/data/services/tmdb_image_resolver.dart';
import '../../../../shared/domain/value_objects/media_title.dart';
import '../../../../shared/domain/value_objects/media_id.dart';
import '../../../../shared/domain/value_objects/content_reference.dart';
import '../../../../core/storage/repositories/iptv_local_repository.dart';
import '../../../../core/state/app_state_controller.dart';
import '../../domain/repositories/home_feed_repository.dart';
import '../../../../shared/data/services/tmdb_cache_data_source.dart';

class HomeFeedRepositoryImpl implements HomeFeedRepository {
  HomeFeedRepositoryImpl(
    this._moviesRemote,
    this._tvRemote,
    this._iptvLocal,
    this._movieRepository,
    this._tvRepository,
    this._images,
    this._appState,
  ) : _tmdbCache = sl<TmdbCacheDataSource>();

  // Datasources / services
  final TmdbMovieRemoteDataSource _moviesRemote;
  final TmdbTvRemoteDataSource _tvRemote;
  final IptvLocalRepository _iptvLocal;
  final MovieRepository _movieRepository;
  final TvRepository _tvRepository;
  final TmdbImageResolver _images;
  final AppStateController _appState;
  final TmdbCacheDataSource _tmdbCache;

  // Limite de pré-chargement TMDB par catégorie
  static const int _preloadPerCategory = 5;

  // ---------------------------
  // HERO
  // ---------------------------

  @override
  Future<List<MovieSummary>> getHeroMovies() async {
    // 1) Trending
    final trending = await _moviesRemote.fetchTrendingMovies(window: 'week');

    // 2) Restreindre aux contenus présents sur l’IPTV
    final available = await _iptvLocal.getAvailableTmdbIds();
    final filtered = trending
        .where((m) => m.posterPath != null && available.contains(m.id))
        .toList();

    // 3) Pré-charger (cache) le tout 1er héro pour logo/synopsis instantanés
    if (filtered.isNotEmpty) {
      final first = filtered.first;
      try {
        final detail = await _moviesRemote.fetchMovie(first.id);
        await _tmdbCache.putMovieDetail(first.id, detail.toCache());
      } catch (_) {
        // silencieux
      }
    }

    // 4) Mapper en MovieSummary
    final list = filtered.map(_mapMovie).whereType<MovieSummary>().toList();

    // Limiter à 20 pour le carrousel héro
    return list.length > 20 ? list.sublist(0, 20) : list;
  }

  // ---------------------------
  // CONTINUE WATCHING
  // ---------------------------

  @override
  Future<List<MovieSummary>> getContinueWatchingMovies() =>
      _movieRepository.getContinueWatching();

  @override
  Future<List<TvShowSummary>> getContinueWatchingShows() =>
      _tvRepository.getContinueWatching();

  // ---------------------------
  // IPTV CATÉGORIES (pré-charge 5, reste léger)
  // ---------------------------

  @override
  Future<Map<String, List<ContentReference>>> getIptvCategoryLists() async {
    final result = <String, List<ContentReference>>{};

    final active = _appState.activeIptvSourceIds;
    if (active.isEmpty) return result;

    final accounts = await _iptvLocal.getAccounts();
    for (final account in accounts) {
      if (!active.contains(account.id)) continue;

      final playlists = await _iptvLocal.getPlaylists(account.id);
      for (final pl in playlists) {
        final visibleKey = '${account.alias}/${_cleanCategoryTitle(pl.title)}';

        // Séparer items TMDB connus
        final withTmdbId = pl.items.where((i) => i.tmdbId != null).toList();
        final firstBatch = withTmdbId.take(_preloadPerCategory).toList();

        // 1) Pré-enrichir les N premiers (films = fetch si besoin; séries = cache only)
        final enriched = <ContentReference>[];
        for (final item in firstBatch) {
          final ref = await _enrichFirstBatchItem(item);
          if (ref != null) enriched.add(ref);
        }

        // 2) Ajouter ensuite le flux “léger” (zéro appel TMDB ici)
        final lightTail = pl.items.skip(enriched.length).map((i) {
          return ContentReference(
            id: (i.tmdbId ?? i.streamId).toString(),
            title: MediaTitle(i.title),
            type: i.type == XtreamPlaylistItemType.series ? ContentType.series : ContentType.movie,
            poster: i.posterUrl != null && i.posterUrl!.isNotEmpty ? Uri.tryParse(i.posterUrl!) : null,
          );
        });

        final items = <ContentReference>[...enriched, ...lightTail];

        if (items.isNotEmpty) {
          result[visibleKey] = items;
        }
      }
    }

    return result;
  }

  // ---------------------------
  // ENRICHISSEMENT "à la volée" d’un ContentReference léger
  // ---------------------------

  @override
  Future<ContentReference> enrichReference(ContentReference ref) async {
    final idNum = int.tryParse(ref.id);
    if (idNum == null) return ref;

    Map<String, dynamic>? data;

    final isSeries = ref.type == ContentType.series;
    if (isSeries) {
      // 1) TV: d’abord cache
      data = await _tmdbCache.getTvDetail(idNum);
      if (data == null) {
        // 2) Réseau → cache
        try {
          final dto = await _tvRemote.fetchShow(idNum);
          data = dto.toCache();
          await _tmdbCache.putTvDetail(idNum, data);
        } catch (_) {
          // si erreur réseau, on renvoie le ref tel quel
          return ref;
        }
      }

      final images = (data['images'] as Map<String, dynamic>?) ?? const {};
      final posters = (images['posters'] as List<dynamic>? ?? const []);
      final posterPath = _selectPosterNoLang(posters) ?? data['poster_path']?.toString();

      return ContentReference(
        id: ref.id,
        title: ref.title,
        type: ref.type,
        poster: _images.poster(posterPath),
        year: _parseYear(data['first_air_date']?.toString()),
        rating: (data['vote_average'] as num?)?.toDouble(),
      );
    } else {
      // Movie
      data = await _tmdbCache.getMovieDetail(idNum);
      if (data == null) {
        try {
          final dto = await _moviesRemote.fetchMovie(idNum);
          data = dto.toCache();
          await _tmdbCache.putMovieDetail(idNum, data);
        } catch (_) {
          return ref;
        }
      }

      final images = (data['images'] as Map<String, dynamic>?) ?? const {};
      final posters = (images['posters'] as List<dynamic>? ?? const []);
      final posterPath = _selectPosterNoLang(posters) ?? data['poster_path']?.toString();

      return ContentReference(
        id: ref.id,
        title: ref.title,
        type: ref.type,
        poster: _images.poster(posterPath),
        year: _parseYear(data['release_date']?.toString()),
        rating: (data['vote_average'] as num?)?.toDouble(),
      );
    }
  }

  // ---------------------------
  // Helpers d’enrichissement / mapping init
  // ---------------------------

  Future<ContentReference?> _enrichFirstBatchItem(XtreamPlaylistItem item) async {
    final tmdbId = item.tmdbId;
    if (tmdbId == null) return null;

    Map<String, dynamic>? data;
    final isSeries = item.type == XtreamPlaylistItemType.series;

    if (isSeries) {
      // Pour séries : on reste économe → cache only pour pré-batch
      data = await _tmdbCache.getTvDetail(tmdbId);
      // Si null, on laissera l’enrichissement au scroll
    } else {
      // Pour films : on peut faire un fetch pour les 5 premiers (UX héro/cartes)
      data = await _tmdbCache.getMovieDetail(tmdbId);
      if (data == null) {
        try {
          final dto = await _moviesRemote.fetchMovie(tmdbId);
          data = dto.toCache();
          await _tmdbCache.putMovieDetail(tmdbId, data);
        } catch (_) {
          // silencieux
        }
      }
    }

    Uri? posterUri;
    int? year;
    double? rating;

    if (data != null) {
      final images = (data['images'] as Map<String, dynamic>?) ?? const {};
      final posters = (images['posters'] as List<dynamic>? ?? const []);
      final posterPath = _selectPosterNoLang(posters) ?? data['poster_path']?.toString();
      posterUri = _images.poster(posterPath);
      year = _parseYear(isSeries ? data['first_air_date']?.toString() : data['release_date']?.toString());
      rating = (data['vote_average'] as num?)?.toDouble();
    } else {
      posterUri = (item.posterUrl != null && item.posterUrl!.isNotEmpty)
          ? Uri.tryParse(item.posterUrl!)
          : null;
    }

    return ContentReference(
      id: tmdbId.toString(),
      title: MediaTitle(item.title),
      type: isSeries ? ContentType.series : ContentType.movie,
      poster: posterUri,
      year: year,
      rating: rating,
    );
  }

  MovieSummary? _mapMovie(dynamic dto) {
    final poster = _images.poster(dto.posterPath);
    if (poster == null) return null;
    return MovieSummary(
      id: MovieId(dto.id.toString()),
      tmdbId: dto.id,
      title: MediaTitle(dto.title),
      poster: poster,
      backdrop: _images.backdrop(dto.backdropPath),
      releaseYear: _parseYear(dto.releaseDate),
    );
  }

  String _cleanCategoryTitle(String raw) {
    // Ex: "premium-ott.com/Action" -> "Action"
    final idx = raw.indexOf('/');
    if (idx >= 0 && idx < raw.length - 1) {
      return raw.substring(idx + 1);
    }
    return raw;
  }

  String? _selectPosterNoLang(List<dynamic> posters) {
    if (posters.isEmpty) return null;
    String? pathOf(Map<String, dynamic> m) => m['file_path']?.toString();
    num scoreOf(Map<String, dynamic> m) => (m['vote_average'] as num?) ?? 0;

    final list = posters.cast<Map<String, dynamic>>();

    final noLang = list.where((m) => m['iso_639_1'] == null).toList()
      ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (noLang.isNotEmpty) return pathOf(noLang.first);

    final en = list.where((m) => (m['iso_639_1']?.toString().toLowerCase() == 'en')).toList()
      ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (en.isNotEmpty) return pathOf(en.first);

    list.sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    return pathOf(list.first);
  }

  int? _parseYear(String? raw) =>
      (raw != null && raw.isNotEmpty) ? int.tryParse(raw.substring(0, 4)) : null;
}


import '../../../movie/domain/entities/movie_summary.dart';
import '../../../tv/domain/entities/tv_show.dart';
import '../../../../shared/domain/value_objects/content_reference.dart';

/// Contract for the Home feed data needed by the Home page (no UI).
abstract class HomeFeedRepository {
  /// Trending movies on TMDB intersected with IPTV availability.
  Future<List<MovieSummary>> getHeroMovies();

  /// Local-only continue watching for movies.
  Future<List<MovieSummary>> getContinueWatchingMovies();

  /// Local-only continue watching for TV shows.
  Future<List<TvShowSummary>> getContinueWatchingShows();

  /// IPTV categories aggregated by account alias and category name.
  /// Key format: `<accountAlias>/<categoryName>`.
  ///
  /// IMPORTANT:
  /// - Chaque section ne doit pré-enrichir que les 5 premiers éléments.
  /// - Le reste est "léger" (pas d'appel TMDB ici).
  Future<Map<String, List<ContentReference>>> getIptvCategoryLists();

  /// Enrichit un ContentReference “léger” avec les métadonnées TMDB (poster TMDB,
  /// year, rating) via cache->réseau si nécessaire, puis renvoie une copie complète.
  Future<ContentReference> enrichReference(ContentReference ref);
}


import 'package:equatable/equatable.dart';

import 'xtream_playlist_item.dart';

enum XtreamPlaylistType { movies, series }

class XtreamPlaylist extends Equatable {
  const XtreamPlaylist({
    required this.id,
    required this.accountId,
    required this.title,
    required this.type,
    required this.items,
  });

  final String id;
  final String accountId;
  final String title;
  final XtreamPlaylistType type;
  final List<XtreamPlaylistItem> items;

  @override
  List<Object?> get props => [id, accountId, title, type, items];
}


import 'package:equatable/equatable.dart';

enum XtreamPlaylistItemType { movie, series }

class XtreamPlaylistItem extends Equatable {
  const XtreamPlaylistItem({
    required this.accountId,
    required this.categoryId,
    required this.categoryName,
    required this.streamId,
    required this.title,
    required this.type,
    this.overview,
    this.posterUrl,
    this.rating,
    this.releaseYear,
    this.tmdbId,
  });

  final String accountId;
  final String categoryId;
  final String categoryName;
  final int streamId;
  final String title;
  final XtreamPlaylistItemType type;
  final String? overview;
  final String? posterUrl;
  final double? rating;
  final int? releaseYear;
  final int? tmdbId;

  @override
  List<Object?> get props => [
        accountId,
        categoryId,
        categoryName,
        streamId,
        title,
        type,
        overview,
        posterUrl,
        rating,
        releaseYear,
        tmdbId,
      ];
}


import '../../domain/entities/xtream_playlist.dart';
import '../../domain/entities/xtream_playlist_item.dart';
import '../../data/dtos/xtream_category_dto.dart';
import '../../data/dtos/xtream_stream_dto.dart';

class PlaylistMapper {
  const PlaylistMapper();

  List<XtreamPlaylist> buildPlaylists({
    required String accountId,
    required Iterable<XtreamCategoryDto> movieCategories,
    required Iterable<XtreamStreamDto> movieStreams,
    required Iterable<XtreamCategoryDto> seriesCategories,
    required Iterable<XtreamStreamDto> seriesStreams,
  }) {
    final moviePlaylists = _buildPlaylistGroup(
      accountId: accountId,
      categories: movieCategories,
      streams: movieStreams,
      type: XtreamPlaylistType.movies,
      itemType: XtreamPlaylistItemType.movie,
    );
    final seriesPlaylists = _buildPlaylistGroup(
      accountId: accountId,
      categories: seriesCategories,
      streams: seriesStreams,
      type: XtreamPlaylistType.series,
      itemType: XtreamPlaylistItemType.series,
    );
    return [...moviePlaylists, ...seriesPlaylists];
  }

  List<XtreamPlaylist> _buildPlaylistGroup({
    required String accountId,
    required Iterable<XtreamCategoryDto> categories,
    required Iterable<XtreamStreamDto> streams,
    required XtreamPlaylistType type,
    required XtreamPlaylistItemType itemType,
  }) {
    final categoryById = {for (final cat in categories) cat.id: cat};
    final grouped = <String, List<XtreamPlaylistItem>>{};

    for (final stream in streams) {
      final category = categoryById[stream.categoryId];
      final categoryName = category?.name ?? 'Sans catégorie';
      grouped.putIfAbsent(stream.categoryId, () => []);
      grouped[stream.categoryId]!.add(
        XtreamPlaylistItem(
          accountId: accountId,
          categoryId: stream.categoryId,
          categoryName: categoryName,
          streamId: stream.streamId,
          title: stream.name,
          type: itemType,
          overview: stream.plot,
          posterUrl: stream.streamIcon,
          rating: stream.rating ?? stream.rating5Based,
          releaseYear: _parseYear(stream.released),
          tmdbId: stream.tmdbId,
        ),
      );
    }

    return grouped.entries
        .map(
          (entry) => XtreamPlaylist(
            id: '${accountId}_${type.name}_${entry.key}',
            accountId: accountId,
            title: categoryById[entry.key]?.name ?? 'Autres',
            type: type,
            items: entry.value,
          ),
        )
        .toList(growable: false);
  }

  int? _parseYear(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.length < 4) return null;
    final year = int.tryParse(raw.substring(0, 4));
    return year;
  }
}

import '../../domain/entities/xtream_account.dart';
import '../../domain/entities/xtream_catalog_snapshot.dart';
import '../../domain/entities/xtream_playlist.dart';
import '../../domain/repositories/iptv_repository.dart';
import '../../domain/value_objects/xtream_endpoint.dart';
import '../datasources/xtream_cache_data_source.dart';
import '../datasources/xtream_remote_data_source.dart';
import '../../application/services/playlist_mapper.dart';

class IptvRepositoryImpl implements IptvRepository {
  IptvRepositoryImpl(
    this._remote,
    this._cache,
    this._playlistMapper,
  );

  final XtreamRemoteDataSource _remote;
  final XtreamCacheDataSource _cache;
  final PlaylistMapper _playlistMapper;

  @override
  Future<XtreamAccount> addSource({
    required XtreamEndpoint endpoint,
    required String username,
    required String password,
    required String alias,
  }) async {
    final auth = await _remote.authenticate(
      endpoint: endpoint,
      username: username,
      password: password,
    );
    final status = auth.isAuthorized ? XtreamAccountStatus.active : XtreamAccountStatus.error;
    final account = XtreamAccount(
      id: _buildAccountId(endpoint, username),
      alias: alias,
      endpoint: endpoint,
      username: username,
      password: password,
      status: status,
      createdAt: DateTime.now(),
      expirationDate: auth.expiration,
      lastError: auth.isAuthorized ? null : auth.message,
    );
    await _cache.saveAccount(account);
    if (!auth.isAuthorized) {
      throw Exception('Xtream authentication failed: ${auth.message}');
    }
    return account;
  }

  @override
  Future<List<XtreamAccount>> getAccounts() {
    return _cache.getAccounts();
  }

  @override
  Future<void> removeSource(String accountId) {
    return _cache.removeAccount(accountId);
  }

  @override
  Future<XtreamCatalogSnapshot> refreshCatalog(String accountId) async {
    final account = await _cache.getAccount(accountId);
    if (account == null) {
      throw Exception('Unknown Xtream account $accountId');
    }

    final request = XtreamAccountRequest(
      endpoint: account.endpoint,
      username: account.username,
      password: account.password,
    );

    final moviesCategories = await _remote.getVodCategories(request);
    final seriesCategories = await _remote.getSeriesCategories(request);
    final movies = await _remote.getVodStreams(request);
    final series = await _remote.getSeries(request);

    final playlists = _playlistMapper.buildPlaylists(
      accountId: accountId,
      movieCategories: moviesCategories,
      movieStreams: movies,
      seriesCategories: seriesCategories,
      seriesStreams: series,
    );

    await _cache.savePlaylists(accountId, playlists);

    final snapshot = XtreamCatalogSnapshot(
      accountId: accountId,
      lastSyncAt: DateTime.now(),
      movieCount: movies.length,
      seriesCount: series.length,
    );
    await _cache.saveSnapshot(snapshot);
    return snapshot;
  }

  @override
  Future<List<XtreamPlaylist>> listPlaylists(String accountId) {
    return _cache.getPlaylists(accountId);
  }

  String _buildAccountId(XtreamEndpoint endpoint, String username) {
    final normalized = '${endpoint.baseUrl}_${username.toLowerCase()}';
    return normalized;
  }
}

import '../entities/xtream_account.dart';
import '../entities/xtream_catalog_snapshot.dart';
import '../entities/xtream_playlist.dart';
import '../value_objects/xtream_endpoint.dart';

abstract class IptvRepository {
  Future<List<XtreamAccount>> getAccounts();

  Future<XtreamAccount> addSource({
    required XtreamEndpoint endpoint,
    required String username,
    required String password,
    required String alias,
  });

  Future<void> removeSource(String accountId);

  Future<XtreamCatalogSnapshot> refreshCatalog(String accountId);

  Future<List<XtreamPlaylist>> listPlaylists(String accountId);
}

import 'dart:async';

import '../../../di/injector.dart';
import '../../../state/app_state_controller.dart';
import '../../../utils/logger.dart';
import '../../data/datasources/xtream_cache_data_source.dart';
import '../usecases/refresh_xtream_catalog.dart';

class XtreamSyncService {
  XtreamSyncService(
    this._state,
    this._refresh,
    this._cache, {
    AppLogger? logger,
    Duration? interval,
  })  : _logger = logger ?? sl<AppLogger>(),
        _interval = interval ?? const Duration(hours: 2);

  final AppStateController _state;
  final RefreshXtreamCatalog _refresh;
  final XtreamCacheDataSource _cache;
  final AppLogger _logger;

  Duration _interval;
  Timer? _timer;
  bool _syncing = false;

  Duration get interval => _interval;

  void setInterval(Duration interval) {
    _interval = interval;
    if (_timer != null) {
      stop();
      start();
    }
  }

  void start() {
    if (_timer != null) return;
    _logger.info('XtreamSyncService starting (interval: ${_interval.inMinutes}m)');
    _timer = Timer.periodic(_interval, (_) => _tick());
    // initial tick
    unawaited(_tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _logger.info('XtreamSyncService stopped');
  }

  Future<void> _tick() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final sources = _state.activeIptvSourceIds;
      if (sources.isEmpty) return;
      for (final accountId in sources) {
        try {
          final snapshot = await _cache.getSnapshot(
            accountId,
            policy: XtreamCacheDataSource.snapshotPolicy,
          );
          if (snapshot == null) {
            _logger.info('Xtream sync: refreshing account $accountId');
            await _refresh(accountId);
          }
        } catch (error, stack) {
          _logger.error('Xtream sync failed for $accountId', error, stack);
        }
      }
    } finally {
      _syncing = false;
    }
  }
}


import '../../../core/config/models/app_config.dart';
import '../../../core/network/network_executor.dart';
import '../../../core/preferences/locale_preferences.dart';

class TmdbClient {
  TmdbClient(
    this._executor,
    this._config,
    this._localePreferences,
  );

  final NetworkExecutor _executor;
  final AppConfig _config;
  final LocalePreferences _localePreferences;

  static const _host = 'api.themoviedb.org';
  static const _version = '3';

  Future<R> get<R>({
    required String path,
    Map<String, dynamic>? query,
    required R Function(Map<String, dynamic> json) mapper,
  }) {
    final apiKey = _config.network.tmdbApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw StateError('TMDB API key is missing from configuration.');
    }
    final params = <String, dynamic>{
      'api_key': apiKey,
      'language': _localePreferences.languageCode,
      ...?query,
    };

    final uri = Uri.https(_host, '/$_version/$path', params.map((k, v) => MapEntry(k, '$v')));

    return _executor.run<Map<String, dynamic>, R>(
      request: (client) => client.getUri<Map<String, dynamic>>(uri),
      mapper: mapper,
    );
  }

  Future<Map<String, dynamic>> getJson(String path, {Map<String, dynamic>? query}) {
    return get<Map<String, dynamic>>(path: path, query: query, mapper: (json) => json);
  }
}

class TmdbImageResolver {
  const TmdbImageResolver({this.baseUrl = 'https://image.tmdb.org/t/p/'});

  final String baseUrl;

  Uri? poster(String? path, {String size = 'w500'}) => _build(path, size);
  Uri? backdrop(String? path, {String size = 'w780'}) => _build(path, size);
  Uri? logo(String? path, {String size = 'w500'}) => _build(path, size);
  Uri? still(String? path, {String size = 'w300'}) => _build(path, size);

  Uri? _build(String? path, String size) {
    if (path == null || path.isEmpty) return null;
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$size$normalized');
  }
}


import '../../../core/storage/repositories/content_cache_repository.dart';
import '../../../core/storage/services/cache_policy.dart';

class TmdbCacheDataSource {
  TmdbCacheDataSource(this._cache);

  final ContentCacheRepository _cache;

  // 7 jours de TTL pour les détails TMDB
  static const CachePolicy detailPolicy = CachePolicy(ttl: Duration(days: 7));

  String _movieKey(int id) => 'tmdb_movie_detail_$id';
  String _tvKey(int id) => 'tmdb_tv_detail_$id';

  Future<Map<String, dynamic>?> getMovieDetail(int id) =>
      _cache.getWithPolicy(_movieKey(id), detailPolicy);

  Future<Map<String, dynamic>?> getTvDetail(int id) =>
      _cache.getWithPolicy(_tvKey(id), detailPolicy);

  Future<void> putMovieDetail(int id, Map<String, dynamic> json) =>
      _cache.put(key: _movieKey(id), type: 'tmdb_detail', payload: json);

  Future<void> putTvDetail(int id, Map<String, dynamic> json) =>
      _cache.put(key: _tvKey(id), type: 'tmdb_detail', payload: json);
}

class TmdbMovieDetailDto {
  TmdbMovieDetailDto({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.logoPath,
    required this.releaseDate,
    required this.runtime,
    required this.voteAverage,
    required this.genres,
    required this.cast,
    required this.directors,
    required this.recommendations,
    this.belongsToCollection,
  });

  factory TmdbMovieDetailDto.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as Map<String, dynamic>?;
    final logos = images?['logos'] as List<dynamic>? ?? const [];
    final logoPath = _selectLogo(logos);
    final credits = json['credits'] as Map<String, dynamic>?;
    final cast = (credits?['cast'] as List<dynamic>? ?? const [])
        .map((item) => TmdbMovieCastDto.fromJson(item as Map<String, dynamic>))
        .toList();
    final crew = (credits?['crew'] as List<dynamic>? ?? const [])
        .map((item) => TmdbMovieCrewDto.fromJson(item as Map<String, dynamic>))
        .toList();
    final recommendations =
        ((json['recommendations'] as Map<String, dynamic>?)?['results']
                    as List<dynamic>? ??
                const [])
            .map(
              (item) =>
                  TmdbMovieSummaryDto.fromJson(item as Map<String, dynamic>),
            )
            .toList();

    return TmdbMovieDetailDto(
      id: json['id'] as int,
      title:
          json['title']?.toString() ??
          json['original_title']?.toString() ??
          'Untitled',
      overview: json['overview']?.toString() ?? '',
      posterPath: json['poster_path']?.toString(),
      backdropPath: json['backdrop_path']?.toString(),
      logoPath: logoPath,
      releaseDate: json['release_date']?.toString(),
      runtime: json['runtime'] as int?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      genres: (json['genres'] as List<dynamic>? ?? const [])
          .map((g) => g['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList(),
      cast: cast,
      directors: crew
          .where((member) => member.job?.toLowerCase() == 'director')
          .toList(),
      recommendations: recommendations,
      belongsToCollection: json['belongs_to_collection'] is Map<String, dynamic>
          ? TmdbCollectionRefDto.fromJson(
              json['belongs_to_collection'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final String? logoPath;
  final String? releaseDate;
  final int? runtime;
  final double? voteAverage;
  final List<String> genres;
  final List<TmdbMovieCastDto> cast;
  final List<TmdbMovieCrewDto> directors;
  final List<TmdbMovieSummaryDto> recommendations;
  final TmdbCollectionRefDto? belongsToCollection;

  Map<String, dynamic> toCache() {
  // On réutilise les champs déjà parsés + on propage les posters/logos
  return {
    'id': id,
    'title': title,
    'overview': overview,
    'poster_path': posterPath,
    'backdrop_path': backdropPath,
    'release_date': releaseDate,
    'runtime': runtime,
    'vote_average': voteAverage,
    'genres': genres.map((name) => {'name': name}).toList(),
    'credits': {
      'cast': cast.map((c) => c.toJson()).toList(),
      'crew': directors.map((d) => d.toJson()).toList(),
    },
    'recommendations': {
      'results': recommendations.map((r) => r.toJson()).toList(),
    },
    if (belongsToCollection != null)
      'belongs_to_collection': belongsToCollection!.toJson(),
    // IMPORTANT : inclure images.logos + images.posters
    'images': {
      'logos': logoPath != null
          ? [
              {
                'file_path': logoPath,
                'vote_average': voteAverage,
                'iso_639_1': 'fr', // ou null, on ne force rien en pratique (non bloquant)
              }
            ]
          : [],
      // on ne les a pas tous ici, mais si l’API a renvoyé images dans fromJson,
      // tu peux opter pour une copie “brute” si tu la conserves ailleurs.
      // Ici on reste minimaliste : le fallback utilisera poster_path si pas de posters listés en cache.
      'posters': [],
    },
  };
}

  factory TmdbMovieDetailDto.fromCache(Map<String, dynamic> json) {
    return TmdbMovieDetailDto.fromJson(json);
  }

  static String? _selectLogo(List<dynamic> logos) {
    if (logos.isEmpty) return null;

    final list = logos.cast<Map<String, dynamic>>();
    String? path(Map<String, dynamic> m) => m['file_path']?.toString();

    // 1) FR
    final fr =
        list
            .where((m) => (m['iso_639_1']?.toString().toLowerCase() == 'fr'))
            .toList()
          ..sort(
            (a, b) => ((b['vote_average'] as num? ?? 0).compareTo(
              a['vote_average'] as num? ?? 0,
            )),
          );
    if (fr.isNotEmpty) return path(fr.first);

    // 2) EN
    final en =
        list
            .where((m) => (m['iso_639_1']?.toString().toLowerCase() == 'en'))
            .toList()
          ..sort(
            (a, b) => ((b['vote_average'] as num? ?? 0).compareTo(
              a['vote_average'] as num? ?? 0,
            )),
          );
    if (en.isNotEmpty) return path(en.first);

    // 3) Sans langue
    final noLang = list.where((m) => m['iso_639_1'] == null).toList()
      ..sort(
        (a, b) => ((b['vote_average'] as num? ?? 0).compareTo(
          a['vote_average'] as num? ?? 0,
        )),
      );
    if (noLang.isNotEmpty) return path(noLang.first);

    // 4) Fallback : meilleur score
    list.sort(
      (a, b) => ((b['vote_average'] as num? ?? 0).compareTo(
        a['vote_average'] as num? ?? 0,
      )),
    );
    return path(list.first);
  }
}

class TmdbCollectionRefDto {
  TmdbCollectionRefDto({required this.id, required this.name, this.posterPath});

  factory TmdbCollectionRefDto.fromJson(Map<String, dynamic> json) =>
      TmdbCollectionRefDto(
        id: json['id'] as int,
        name: json['name']?.toString() ?? 'Collection',
        posterPath: json['poster_path']?.toString(),
      );

  final int id;
  final String name;
  final String? posterPath;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'poster_path': posterPath,
  };
}

class TmdbMovieCastDto {
  TmdbMovieCastDto({
    required this.id,
    required this.name,
    required this.character,
    required this.profilePath,
  });

  factory TmdbMovieCastDto.fromJson(Map<String, dynamic> json) {
    return TmdbMovieCastDto(
      id: json['id'] as int,
      name: json['name']?.toString() ?? 'Unknown',
      character: json['character']?.toString(),
      profilePath: json['profile_path']?.toString(),
    );
  }

  final int id;
  final String name;
  final String? character;
  final String? profilePath;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'character': character,
    'profile_path': profilePath,
  };
}

class TmdbMovieCrewDto {
  TmdbMovieCrewDto({required this.id, required this.name, required this.job});

  factory TmdbMovieCrewDto.fromJson(Map<String, dynamic> json) {
    return TmdbMovieCrewDto(
      id: json['id'] as int,
      name: json['name']?.toString() ?? 'Unknown',
      job: json['job']?.toString(),
    );
  }

  final int id;
  final String name;
  final String? job;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'job': job};
}

class TmdbMovieSummaryDto {
  TmdbMovieSummaryDto({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.backdropPath,
    required this.releaseDate,
    required this.voteAverage,
  });

  factory TmdbMovieSummaryDto.fromJson(Map<String, dynamic> json) {
    return TmdbMovieSummaryDto(
      id: json['id'] as int,
      title:
          json['title']?.toString() ??
          json['original_title']?.toString() ??
          'Untitled',
      posterPath: json['poster_path']?.toString(),
      backdropPath: json['backdrop_path']?.toString(),
      releaseDate: json['release_date']?.toString(),
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
    );
  }

  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double? voteAverage;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'poster_path': posterPath,
    'backdrop_path': backdropPath,
    'release_date': releaseDate,
    'vote_average': voteAverage,
  };
}


class TmdbTvDetailDto {
  TmdbTvDetailDto({
    required this.id,
    required this.name,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.logoPath,
    required this.firstAirDate,
    required this.lastAirDate,
    required this.status,
    required this.voteAverage,
    required this.genres,
    required this.cast,
    required this.creators,
    required this.seasons,
    required this.recommendations,
  });

  factory TmdbTvDetailDto.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as Map<String, dynamic>?;
    final logos = images?['logos'] as List<dynamic>? ?? const [];
    final logoPath = _selectLogo(logos);
    final credits = json['credits'] as Map<String, dynamic>?;
    final cast = (credits?['cast'] as List<dynamic>? ?? const [])
        .map((item) => TmdbTvCastDto.fromJson(item as Map<String, dynamic>))
        .toList();
    final crew = (credits?['crew'] as List<dynamic>? ?? const [])
        .map((item) => TmdbTvCrewDto.fromJson(item as Map<String, dynamic>))
        .toList();
    final recommendations = ((json['recommendations'] as Map<String, dynamic>?)?['results'] as List<dynamic>? ?? const [])
        .map((item) => TmdbTvSummaryDto.fromJson(item as Map<String, dynamic>))
        .toList();
    final createdBy = (json['created_by'] as List<dynamic>? ?? const [])
        .map((c) => TmdbTvCrewDto.fromJson(c as Map<String, dynamic>))
        .toList();
    final creators = createdBy.isNotEmpty
        ? createdBy
        : crew.where((member) => member.job?.toLowerCase() == 'creator').toList();

    return TmdbTvDetailDto(
      id: json['id'] as int,
      name: json['name']?.toString() ?? json['original_name']?.toString() ?? 'Untitled',
      overview: json['overview']?.toString() ?? '',
      posterPath: json['poster_path']?.toString(),
      backdropPath: json['backdrop_path']?.toString(),
      logoPath: logoPath,
      firstAirDate: json['first_air_date']?.toString(),
      lastAirDate: json['last_air_date']?.toString(),
      status: json['status']?.toString(),
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      genres: (json['genres'] as List<dynamic>? ?? const [])
          .map((g) => g['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList(),
      cast: cast,
      creators: creators,
      seasons: (json['seasons'] as List<dynamic>? ?? const [])
          .map((season) => TmdbTvSeasonDto.fromJson(season as Map<String, dynamic>))
          .toList(),
      recommendations: recommendations,
    );
  }

  final int id;
  final String name;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final String? logoPath;
  final String? firstAirDate;
  final String? lastAirDate;
  final String? status;
  final double? voteAverage;
  final List<String> genres;
  final List<TmdbTvCastDto> cast;
  final List<TmdbTvCrewDto> creators;
  final List<TmdbTvSeasonDto> seasons;
  final List<TmdbTvSummaryDto> recommendations;

  Map<String, dynamic> toCache() => {
        'id': id,
        'name': name,
        'overview': overview,
        'poster_path': posterPath,
        'backdrop_path': backdropPath,
        'images': {
          'logos': logoPath != null
              ? [
                  {
                    'file_path': logoPath,
                    'vote_average': voteAverage,
                    'iso_639_1': null,
                  }
                ]
              : [],
        },
        'first_air_date': firstAirDate,
        'last_air_date': lastAirDate,
        'status': status,
        'vote_average': voteAverage,
        'genres': genres.map((g) => {'name': g}).toList(),
        'credits': {
          'cast': cast.map((c) => c.toJson()).toList(),
          'crew': creators.map((c) => c.toJson()).toList(),
        },
        'created_by': creators.map((c) => c.toJson()).toList(),
        'seasons': seasons.map((season) => season.toJson()).toList(),
        'recommendations': {
          'results': recommendations.map((r) => r.toJson()).toList(),
        },
      };

  factory TmdbTvDetailDto.fromCache(Map<String, dynamic> json) => TmdbTvDetailDto.fromJson(json);
}

String? _selectLogo(List<dynamic> logos) {
  if (logos.isEmpty) return null;
  logos.sort((a, b) => ((b['vote_average'] as num?)?.compareTo((a['vote_average'] as num?) ?? 0) ?? 0));
  final best = logos.cast<Map<String, dynamic>>().firstWhere(
        (logo) => (logo['iso_639_1']?.toString().isNotEmpty ?? false),
        orElse: () => logos.first as Map<String, dynamic>,
      );
  return best['file_path']?.toString();
}

class TmdbTvCastDto {
  TmdbTvCastDto({
    required this.id,
    required this.name,
    required this.character,
    required this.profilePath,
  });

  factory TmdbTvCastDto.fromJson(Map<String, dynamic> json) {
    return TmdbTvCastDto(
      id: json['id'] as int,
      name: json['name']?.toString() ?? 'Unknown',
      character: json['character']?.toString(),
      profilePath: json['profile_path']?.toString(),
    );
  }

  final int id;
  final String name;
  final String? character;
  final String? profilePath;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'character': character,
        'profile_path': profilePath,
      };
}

class TmdbTvCrewDto {
  TmdbTvCrewDto({
    required this.id,
    required this.name,
    required this.job,
  });

  factory TmdbTvCrewDto.fromJson(Map<String, dynamic> json) {
    return TmdbTvCrewDto(
      id: json['id'] as int,
      name: json['name']?.toString() ?? 'Unknown',
      job: json['job']?.toString(),
    );
  }

  final int id;
  final String name;
  final String? job;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'job': job,
      };
}

class TmdbTvSeasonDto {
  TmdbTvSeasonDto({
    required this.id,
    required this.name,
    required this.overview,
    required this.posterPath,
    required this.airDate,
    required this.seasonNumber,
    required this.episodeCount,
  });

  factory TmdbTvSeasonDto.fromJson(Map<String, dynamic> json) {
    return TmdbTvSeasonDto(
      id: json['id'] as int,
      name: json['name']?.toString() ?? 'Season',
      overview: json['overview']?.toString() ?? '',
      posterPath: json['poster_path']?.toString(),
      airDate: json['air_date']?.toString(),
      seasonNumber: json['season_number'] as int? ?? 0,
      episodeCount: json['episode_count'] as int? ?? 0,
    );
  }

  final int id;
  final String name;
  final String overview;
  final String? posterPath;
  final String? airDate;
  final int seasonNumber;
  final int episodeCount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'overview': overview,
        'poster_path': posterPath,
        'air_date': airDate,
        'season_number': seasonNumber,
        'episode_count': episodeCount,
      };
}

class TmdbTvSummaryDto {
  TmdbTvSummaryDto({
    required this.id,
    required this.name,
    required this.posterPath,
    required this.backdropPath,
    required this.firstAirDate,
    required this.voteAverage,
  });

  factory TmdbTvSummaryDto.fromJson(Map<String, dynamic> json) {
    return TmdbTvSummaryDto(
      id: json['id'] as int,
      name: json['name']?.toString() ?? json['original_name']?.toString() ?? 'Untitled',
      posterPath: json['poster_path']?.toString(),
      backdropPath: json['backdrop_path']?.toString(),
      firstAirDate: json['first_air_date']?.toString(),
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
    );
  }

  final int id;
  final String name;
  final String? posterPath;
  final String? backdropPath;
  final String? firstAirDate;
  final double? voteAverage;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'poster_path': posterPath,
        'backdrop_path': backdropPath,
        'first_air_date': firstAirDate,
        'vote_average': voteAverage,
      };
}


import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../database/sqlite_database.dart';
import '../services/cache_policy.dart';

class ContentCacheRepository {
  Future<Database> get _db => LocalDatabase.instance();

  Future<void> put({
    required String key,
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final db = await _db;
    await db.insert(
      'content_cache',
      {
        'cache_key': key,
        'cache_type': type,
        'payload': jsonEncode(payload),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> get(String key) async {
    final db = await _db;
    final rows = await db.query('content_cache', where: 'cache_key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['payload'] as String) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> getWithPolicy(String key, CachePolicy policy) async {
    final db = await _db;
    final rows = await db.query('content_cache', where: 'cache_key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(rows.first['updated_at'] as int);
    if (policy.isExpired(updatedAt)) {
      await db.delete('content_cache', where: 'cache_key = ?', whereArgs: [key]);
      return null;
    }
    return jsonDecode(rows.first['payload'] as String) as Map<String, dynamic>;
  }

  Future<void> clearType(String type) async {
    final db = await _db;
    await db.delete('content_cache', where: 'cache_type = ?', whereArgs: [type]);
  }
}


class CachePolicy {
  const CachePolicy({required this.ttl});

  final Duration ttl;

  bool isExpired(DateTime updatedAt) => DateTime.now().difference(updatedAt) > ttl;
}


import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class LocalDatabase {
  LocalDatabase._();

  static Database? _instance;

  static Future<Database> instance() async {
    if (_instance != null) return _instance!;

    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'movi.db');

    _instance = await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE watchlist (
            content_id TEXT NOT NULL,
            content_type TEXT NOT NULL,
            title TEXT NOT NULL,
            poster TEXT,
            added_at INTEGER NOT NULL,
            PRIMARY KEY (content_id, content_type)
          );
        ''');
        await db.execute('''
          CREATE TABLE content_cache (
            cache_key TEXT PRIMARY KEY,
            cache_type TEXT NOT NULL,
            payload TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE iptv_accounts (
            account_id TEXT PRIMARY KEY,
            alias TEXT NOT NULL,
            endpoint TEXT NOT NULL,
            username TEXT NOT NULL,
            password TEXT NOT NULL,
            status TEXT NOT NULL,
            expiration INTEGER,
            created_at INTEGER NOT NULL,
            last_error TEXT
          );
        ''');
        await db.execute('''
          CREATE TABLE iptv_playlists (
            account_id TEXT NOT NULL,
            category_id TEXT NOT NULL,
            payload TEXT NOT NULL,
            updated_at INTEGER NOT NULL,
            PRIMARY KEY (account_id, category_id)
          );
        ''');
        await db.execute('''
          CREATE TABLE continue_watching (
            content_id TEXT NOT NULL,
            content_type TEXT NOT NULL,
            title TEXT NOT NULL,
            poster TEXT,
            position INTEGER NOT NULL,
            duration INTEGER,
            season INTEGER,
            episode INTEGER,
            updated_at INTEGER NOT NULL,
            PRIMARY KEY (content_id, content_type)
          );
        ''');
        await db.execute('''
          CREATE TABLE history (
            content_id TEXT NOT NULL,
            content_type TEXT NOT NULL,
            title TEXT NOT NULL,
            poster TEXT,
            last_played_at INTEGER NOT NULL,
            play_count INTEGER NOT NULL DEFAULT 1,
            last_position INTEGER,
            duration INTEGER,
            season INTEGER,
            episode INTEGER,
            PRIMARY KEY (content_id, content_type)
          );
        ''');

        // User playlists
        await db.execute('''
          CREATE TABLE playlists (
            playlist_id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT,
            cover TEXT,
            owner TEXT NOT NULL,
            is_public INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE playlist_items (
            playlist_id TEXT NOT NULL,
            position INTEGER NOT NULL,
            content_id TEXT NOT NULL,
            content_type TEXT NOT NULL,
            title TEXT NOT NULL,
            poster TEXT,
            runtime INTEGER,
            notes TEXT,
            added_at INTEGER NOT NULL,
            PRIMARY KEY (playlist_id, position)
          );
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE continue_watching (
              content_id TEXT NOT NULL,
              content_type TEXT NOT NULL,
              title TEXT NOT NULL,
              poster TEXT,
              position INTEGER NOT NULL,
              duration INTEGER,
              season INTEGER,
              episode INTEGER,
              updated_at INTEGER NOT NULL,
              PRIMARY KEY (content_id, content_type)
            );
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE history (
              content_id TEXT NOT NULL,
              content_type TEXT NOT NULL,
              title TEXT NOT NULL,
              poster TEXT,
              last_played_at INTEGER NOT NULL,
              play_count INTEGER NOT NULL DEFAULT 1,
              last_position INTEGER,
              duration INTEGER,
              season INTEGER,
              episode INTEGER,
              PRIMARY KEY (content_id, content_type)
            );
          ''');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE playlists (
              playlist_id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              description TEXT,
              cover TEXT,
              owner TEXT NOT NULL,
              is_public INTEGER NOT NULL,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            );
          ''');
          await db.execute('''
            CREATE TABLE playlist_items (
              playlist_id TEXT NOT NULL,
              position INTEGER NOT NULL,
              content_id TEXT NOT NULL,
              content_type TEXT NOT NULL,
              title TEXT NOT NULL,
              poster TEXT,
              runtime INTEGER,
              notes TEXT,
              added_at INTEGER NOT NULL,
              PRIMARY KEY (playlist_id, position)
            );
          ''');
        }
      },
    );

    return _instance!;
  }
}

import 'package:dio/dio.dart';

import '../utils/logger.dart';
import 'network_exceptions.dart';

typedef NetworkCall<T> = Future<Response<T>> Function(Dio client);

class NetworkExecutor {
  NetworkExecutor(this._client, {this.logger});

  final Dio _client;
  final AppLogger? logger;

  Future<R> run<T, R>({
    required NetworkCall<T> request,
    required R Function(T data) mapper,
  }) async {
    try {
      final response = await request(_client);
      final data = response.data;
      if (data == null) {
        throw const NetworkFailure.emptyResponse();
      }
      return mapper(data as T);
    } on DioException catch (error, stackTrace) {
      logger?.error('Network call failed', error, stackTrace);
      throw NetworkFailure.fromDioException(error);
    } catch (error, stackTrace) {
      logger?.error('Unexpected network error', error, stackTrace);
      throw NetworkFailure.unknown(error);
    }
  }
}

import 'package:dio/dio.dart';

import '../config/services/secret_store.dart';
import '../config/models/app_config.dart';
import '../utils/logger.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/locale_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'interceptors/telemetry_interceptor.dart';

class HttpClientFactory {
  const HttpClientFactory({
    required this.config,
    required this.logger,
    required this.secretStore,
    this.localeProvider,
  });

  final AppConfig config;
  final AppLogger logger;
  final SecretStore secretStore;
  final LocaleCodeProvider? localeProvider;

  Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.network.restBaseUrl,
        connectTimeout: config.network.timeouts.connect,
        receiveTimeout: config.network.timeouts.receive,
        sendTimeout: config.network.timeouts.send,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'MOVI/${config.metadata.version} (${config.environment.label})',
        },
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(
        tokenResolver: () async => config.network.tmdbApiKey ?? await secretStore.read('TMDB_API_KEY'),
      ),
      LocaleInterceptor(localeProvider: localeProvider),
      RetryInterceptor(dio: dio, logger: logger),
      TelemetryInterceptor(logger: logger),
    ]);

    return dio;
  }
}

import '../models/app_metadata.dart';
import '../models/feature_flags.dart';
import '../models/network_endpoints.dart';

enum AppEnvironment { dev, staging, prod }

abstract class EnvironmentFlavor {
  AppEnvironment get environment;
  String get label;
  NetworkEndpoints get network;
  FeatureFlags get defaultFlags;
  AppMetadata get metadata;

  bool get isProduction => environment == AppEnvironment.prod;
}

class NetworkTimeouts {
  const NetworkTimeouts({
    this.connect = const Duration(seconds: 10),
    this.receive = const Duration(seconds: 15),
    this.send = const Duration(seconds: 10),
  });

  final Duration connect;
  final Duration receive;
  final Duration send;

  NetworkTimeouts copyWith({
    Duration? connect,
    Duration? receive,
    Duration? send,
  }) {
    return NetworkTimeouts(
      connect: connect ?? this.connect,
      receive: receive ?? this.receive,
      send: send ?? this.send,
    );
  }
}

class NetworkEndpoints {
  const NetworkEndpoints({
    required this.restBaseUrl,
    required this.imageBaseUrl,
    this.tmdbApiKey,
    this.timeouts = const NetworkTimeouts(),
  });

  final String restBaseUrl;
  final String imageBaseUrl;
  final String? tmdbApiKey;
  final NetworkTimeouts timeouts;

  NetworkEndpoints copyWith({
    String? restBaseUrl,
    String? imageBaseUrl,
    String? tmdbApiKey,
    NetworkTimeouts? timeouts,
  }) {
    return NetworkEndpoints(
      restBaseUrl: restBaseUrl ?? this.restBaseUrl,
      imageBaseUrl: imageBaseUrl ?? this.imageBaseUrl,
      tmdbApiKey: tmdbApiKey ?? this.tmdbApiKey,
      timeouts: timeouts ?? this.timeouts,
    );
  }
}

// lib/src/core/widgets/movi_items_list.dart
import 'dart:async';
import 'package:flutter/material.dart';

/// Horizontal list section with a title aligned to the left edge,
/// capable of notifying the visible range on horizontal scroll to enable
/// lazy enrichment of items (TMDB fetch on demand).
class MoviItemsList extends StatefulWidget {
  const MoviItemsList({
    super.key,
    required this.title,
    required this.items,
    this.itemSpacing = 16,
    this.horizontalPadding = const EdgeInsets.symmetric(horizontal: 20),
    this.titlePadding = 20,
    this.subtitle,
    // Lazy-enrich hooks:
    this.onViewportChanged,
    this.estimatedItemWidth,
    this.preloadAhead = 2,
  }) : assert(itemSpacing >= 0, 'itemSpacing must be non-negative');

  /// Section title displayed above the list.
  final String title;

  /// Optional secondary label displayed to the right of the title.
  final String? subtitle;

  /// Cards/widgets displayed horizontally.
  final List<Widget> items;

  /// Spacing between each card in the horizontal list.
  final double itemSpacing;

  /// Padding applied to the horizontal list.
  final EdgeInsetsGeometry horizontalPadding;

  /// Left/right padding applied to the title text row.
  final double titlePadding;

  /// Called when the horizontal viewport likely exposes a new range.
  /// Signature: (startIndex, countVisibleApprox).
  final void Function(int start, int count)? onViewportChanged;

  /// Estimated width of a single card (for range calc). If null, no callback.
  final double? estimatedItemWidth;

  /// How many items to preload ahead of viewport on each side.
  final int preloadAhead;

  @override
  State<MoviItemsList> createState() => _MoviItemsListState();
}

class _MoviItemsListState extends State<MoviItemsList> {
  final _ctrl = ScrollController();
  Timer? _debounce;

  double get _hPadStart {
    if (widget.horizontalPadding is EdgeInsets) {
      return (widget.horizontalPadding as EdgeInsets).left;
    }
    if (widget.horizontalPadding is EdgeInsetsDirectional) {
      return (widget.horizontalPadding as EdgeInsetsDirectional).start;
    }
    return 0;
  }

  double get _hPadEnd {
    if (widget.horizontalPadding is EdgeInsets) {
      return (widget.horizontalPadding as EdgeInsets).right;
    }
    if (widget.horizontalPadding is EdgeInsetsDirectional) {
      return (widget.horizontalPadding as EdgeInsetsDirectional).end;
    }
    return 0;
  }

  void _notifyViewportChangedDebounced() {
    if (widget.onViewportChanged == null || widget.estimatedItemWidth == null) return;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), _notifyViewportChangedNow);
  }

  void _notifyViewportChangedNow() {
    if (!mounted) return;
    if (widget.onViewportChanged == null || widget.estimatedItemWidth == null) return;

    // Taille du viewport disponible pour les cartes, hors padding horizontal.
    final viewportWidth = context.size?.width ?? 0;
    final effectiveWidth = (viewportWidth - _hPadStart - _hPadEnd).clamp(0, double.infinity);

    if (effectiveWidth <= 0) return;

    final unit = widget.estimatedItemWidth! + widget.itemSpacing;
    if (unit <= 0) return;

    // Position actuelle (offset) -> index de départ approximatif.
    final start = (_ctrl.offset / unit).floor().clamp(0, widget.items.length - 1);
    // Nombre d’éléments visibles approximatif.
    final visible = (effectiveWidth / unit).ceil().clamp(1, widget.items.length);
    final preload = widget.preloadAhead;

    final startWithPreload = (start - preload).clamp(0, (widget.items.length - 1).clamp(0, 1 << 30));
    final endWithPreload = (start + visible - 1 + preload).clamp(0, widget.items.length - 1);
    final count = (endWithPreload - startWithPreload + 1).clamp(0, widget.items.length);

    widget.onViewportChanged!.call(startWithPreload, count);
  }

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_notifyViewportChangedDebounced);

    // Appel initial (post-frame) pour précharger le premier viewport.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyViewportChangedNow();
    });
  }

  @override
  void didUpdateWidget(covariant MoviItemsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si le nombre d’items change, renvoyer une info de viewport.
    if (oldWidget.items.length != widget.items.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyViewportChangedNow();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl
      ..removeListener(_notifyViewportChangedDebounced)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: widget.titlePadding,
            end: widget.titlePadding,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.subtitle != null)
                Text(
                  widget.subtitle!,
                  style: textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFA6A6A6),
                      ) ??
                      const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFA6A6A6),
                      ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          controller: _ctrl,
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: widget.horizontalPadding,
          child: Row(
            children: [
              for (int i = 0; i < widget.items.length; i++) ...[
                widget.items[i],
                if (i != widget.items.length - 1) SizedBox(width: widget.itemSpacing),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/movi_media.dart';
import '../router/app_router.dart';
import '../utils/app_assets.dart';
import 'movi_marquee_text.dart';
import 'movi_pill.dart';

Image _buildPosterImage(String source, double width, double height) {
  final errorPlaceholder = Container(
    width: width,
    height: height,
    color: const Color(0xFF222222),
    child: const Center(child: Icon(Icons.broken_image, size: 32, color: Colors.white54)),
  );

  if (source.startsWith('http')) {
    return Image.network(
      source,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => errorPlaceholder,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: width,
          height: height,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
        );
      },
    );
  }

  return Image.asset(
    source,
    width: width,
    height: height,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => errorPlaceholder,
  );
}

/// Card used to display either a movie or a series.
class MoviMediaCard extends StatefulWidget {
  const MoviMediaCard({
    super.key,
    required this.media,
    this.width = 150,
    this.height = 225,
  });

  final MoviMedia media;
  final double width;
  final double height;

  @override
  State<MoviMediaCard> createState() => _MoviMediaCardState();
}

class _MoviMediaCardState extends State<MoviMediaCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.titleSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        );

    return GestureDetector(
      onTap: () => _handleTap(context, widget.media),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: widget.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _PosterWithOverlay(
              media: widget.media,
              width: widget.width,
              height: widget.height,
            ),
            const SizedBox(height: 12),
            MoviMarqueeText(
              text: widget.media.title,
              style: textStyle,
              maxWidth: widget.width,
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, MoviMedia media) {
    switch (media.type) {
      case MoviMediaType.movie:
        context.push(AppRouteNames.movie);
        break;
      case MoviMediaType.series:
        context.push(AppRouteNames.tv);
        break;
    }
  }
}

class _PosterWithOverlay extends StatelessWidget {
  const _PosterWithOverlay({
    required this.media,
    required this.width,
    required this.height,
  });

  final MoviMedia media;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          SizedBox(
            width: width,
            height: height,
            child: _buildPosterImage(media.poster, width, height),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 80,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xFF404040),
                      Color(0x00404040),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MoviPill(media.year, large: false),
                const SizedBox(width: 4),
                MoviPill(
                  media.rating,
                  large: false,
                  trailingIcon: Image.asset(
                    AppAssets.iconStarFilled,
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Abstraction que la couche data devra implémenter pour fournir les
/// contenus (films, séries, playlists, etc.).
abstract class ContentRepository {
  Future<List<String>> fetchContinueWatching();
  Future<List<String>> fetchFeatured();
}


// lib/src/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/features/settings/presentation/pages/iptv_connect_page.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/library/presentation/pages/library_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/movie/presentation/pages/movie_detail_page.dart';
import '../../features/person/presentation/pages/person_detail_page.dart';
import '../../features/playlist/presentation/pages/playlist_detail_page.dart';
import '../../features/saga/presentation/pages/saga_detail_page.dart';
import '../../features/tv/presentation/pages/tv_detail_page.dart';

import '../di/injector.dart';
import '../storage/repositories/iptv_local_repository.dart';

class AppRouteNames {
  static const launch = '/launch';
  static const home = '/';
  static const search = '/search';
  static const library = '/library';
  static const settings = '/settings';
  static const movie = '/movie';
  static const person = '/person';
  static const playlist = '/playlist';
  static const saga = '/saga';
  static const tv = '/tv';
}

final appRouter = GoRouter(
  initialLocation: AppRouteNames.launch,
  routes: [
    // --- LAUNCH GATE ---
    GoRoute(
      path: AppRouteNames.launch,
      name: 'launch',
      pageBuilder: (context, state) => const MaterialPage(child: _LaunchGate()),
    ),

    // --- HOME / TABS ---
    GoRoute(
      path: AppRouteNames.home,
      name: 'home',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: HomePage()),
    ),
    GoRoute(
      path: AppRouteNames.search,
      name: 'search',
      pageBuilder: (context, state) => const MaterialPage(child: SearchPage()),
    ),
    GoRoute(
      path: AppRouteNames.library,
      name: 'library',
      pageBuilder: (context, state) => const MaterialPage(child: LibraryPage()),
    ),
    GoRoute(
      path: AppRouteNames.settings,
      name: 'settings',
      pageBuilder: (context, state) =>
          const MaterialPage(child: SettingsPage()),
    ),

    // --- DETAILS ---
    GoRoute(
      path: AppRouteNames.movie,
      name: 'movie_detail',
      pageBuilder: (context, state) =>
          const MaterialPage(child: MovieDetailPage()),
    ),
    GoRoute(
      path: AppRouteNames.person,
      name: 'person_detail',
      pageBuilder: (context, state) =>
          const MaterialPage(child: PersonDetailPage()),
    ),
    GoRoute(
      path: AppRouteNames.playlist,
      name: 'playlist_detail',
      pageBuilder: (context, state) =>
          const MaterialPage(child: PlaylistDetailPage()),
    ),
    GoRoute(
      path: AppRouteNames.saga,
      name: 'saga_detail',
      pageBuilder: (context, state) =>
          const MaterialPage(child: SagaDetailPage()),
    ),
    GoRoute(
      path: AppRouteNames.tv,
      name: 'tv_detail',
      pageBuilder: (context, state) =>
          const MaterialPage(child: TvDetailPage()),
    ),
    GoRoute(
      path: '/settings/iptv/connect',
      name: 'iptv_connect',
      pageBuilder: (context, state) =>
          const MaterialPage(child: IptvConnectPage()),
    ),
  ],
  errorPageBuilder: (context, state) => MaterialPage(
    child: Scaffold(
      body: Center(child: Text('Route introuvable: ${state.error}')),
    ),
  ),
);

/// Page de garde qui choisit Home vs Settings au démarrage.
class _LaunchGate extends StatefulWidget {
  const _LaunchGate();

  @override
  State<_LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<_LaunchGate> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    // On lit le local repo pour vérifier s'il existe AU MOINS un compte IPTV
    final repo = sl<IptvLocalRepository>();
    final accounts = await repo.getAccounts();

    if (!mounted) return;
    if (accounts.isEmpty) {
      // Pas de compte → Settings d'abord
      GoRouter.of(context).go('/settings/iptv/connect');
    } else {
      // Il y a un compte → Home
      GoRouter.of(context).go(AppRouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Splash minimal pendant la décision
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
