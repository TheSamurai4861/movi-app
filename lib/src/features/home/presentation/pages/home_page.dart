// lib/src/features/home/presentation/pages/home_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/models/models.dart';
import 'package:movi/src/core/utils/utils.dart';
import 'package:movi/src/core/widgets/movi_bottom_nav_bar.dart';
import 'package:movi/src/core/widgets/movi_items_list.dart';
import 'package:movi/src/core/widgets/movi_media_card.dart';
import 'package:movi/src/core/widgets/movi_see_all_card.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/features/home/presentation/widgets/continue_watching_card.dart';
import 'package:movi/src/features/home/presentation/widgets/home_hero_carousel.dart';
import 'package:movi/src/features/home/presentation/widgets/home_hero_section.dart';
import 'package:movi/src/features/search/presentation/pages/search_page.dart';
import 'package:movi/src/features/library/presentation/pages/library_page.dart';
import 'package:movi/src/features/settings/presentation/pages/settings_page.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
// logging_service n'est plus utilisé sur la page d'accueil
// overlay_splash supprimé de la page d'accueil

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static const _fadeDuration = Duration(milliseconds: 200);
  static const _navBottomOffset = 0;

  int _selectedIndex = 0;

  void _handleNavTap(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final navIndex = ref.watch(hp.homeNavIndexProvider);
    if (_selectedIndex != navIndex) _selectedIndex = navIndex;

    final pages = <Widget>[
      const _HomeContent(),
      const SearchPage(),
      const LibraryPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                navItems: [
                  MoviBottomNavItem(
                    label: AppLocalizations.of(context)!.navHome,
                    activeIcon: AppAssets.navHomeActive,
                    inactiveIcon: AppAssets.navHome,
                  ),
                  MoviBottomNavItem(
                    label: AppLocalizations.of(context)!.navSearch,
                    activeIcon: AppAssets.navSearchActive,
                    inactiveIcon: AppAssets.navSearch,
                  ),
                  MoviBottomNavItem(
                    label: AppLocalizations.of(context)!.navLibrary,
                    activeIcon: AppAssets.navLibraryActive,
                    inactiveIcon: AppAssets.navLibrary,
                  ),
                  MoviBottomNavItem(
                    label: AppLocalizations.of(context)!.navSettings,
                    activeIcon: AppAssets.navSettingsActive,
                    inactiveIcon: AppAssets.navSettings,
                  ),
                ],
                onItemSelected: (i) {
                  _handleNavTap(i);
                  ref.read(hp.homeNavIndexProvider.notifier).set(i);
                },
              ),
            ),
            // Overlay supprimé : le contenu est affiché directement.
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerStatefulWidget {
  const _HomeContent();

  @override
  ConsumerState<_HomeContent> createState() => _HomeContentState();
}

/// Gère le contenu Home avec overlay de démarrage.
///
/// Comportement de l’overlay:
/// - Démarre visible et se masque dès que le hero ou le premier viewport
///   d’items est précaché (premier à terminer gagne).
/// - Timeout doux de 5 secondes pour éviter de bloquer l’UI en cas de réseau lent.
class _HomeContentState extends ConsumerState<_HomeContent> {
  // Enrichissement TMDB désactivé pour les listes: plus de mémo viewport ni recheck.
  @override
  void initState() {
    super.initState();
    // Déclenche le chargement en post-frame pour éviter
    // la modification de provider durant le build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(hp.homeControllerProvider.notifier).load());
    });
  }

  bool _isScheduled = false;
  void _postFrame(VoidCallback fn) {
    if (_isScheduled) return;
    _isScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fn();
      _isScheduled = false;
    });
  }

  Future<void> _precacheImageUrl(String url) async {
    if (url.isEmpty) return;
    try {
      await precacheImage(NetworkImage(url), context);
    } catch (_) {
      // ignore erreurs réseau; l’overlay ne doit pas bloquer
    }
  }

  static const double _mediaCardWidth =
      150; // doit rester aligné avec MoviMediaCard par défaut
  static const double _itemSpacing = 16; // espace horizontal entre items
  static const double _sectionGap =
      32; // espace VERTICAL entre sections MoviItemsList

  // Afficher uniquement le libellé catégorie (sans "serveur/")
  String _displayCategoryTitle(String raw) {
    final idx = raw.indexOf('/');
    return (idx >= 0 && idx < raw.length - 1) ? raw.substring(idx + 1) : raw;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(hp.homeControllerProvider);
    final controller = ref.read(hp.homeControllerProvider.notifier);

    // Précache héro (sans fermer l’overlay) pour accélérer les réaffichages
    _postFrame(() {
      if (state.hero.isNotEmpty) {
        var heroUrl = ((state.hero.first.backdrop) ?? (state.hero.first.poster))
            .toString();
        if (heroUrl == 'null') heroUrl = '';
        if (heroUrl.isNotEmpty) {
          unawaited(_precacheImageUrl(heroUrl));
        }
      }
    });

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            await controller.refresh();
          },
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
                              style:
                                  (theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.red,
                                  )) ??
                                  theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // On rend le vrai hero avec le state (évite les rebuilds visibles)
              SliverToBoxAdapter(
                child: state.isHeroEmpty
                    ? const _HeroEmptyBanner()
                    : (state.hero.length >= 2)
                    ? HomeHeroCarousel(
                        movies: state.hero.take(10).toList(growable: false),
                      )
                    : HomeHeroSection(
                        movie: state.hero.isNotEmpty ? state.hero.first : null,
                      ),
              ),

              // Marge après le hero: 32px pour uniformiser l'espacement des sections
              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // ===== Section "En cours" =====
              if (state.cwMovies.isNotEmpty || state.cwShows.isNotEmpty)
                SliverToBoxAdapter(
                  child: MoviItemsList(
                    title: 'En cours',
                    itemSpacing: _itemSpacing,
                    // Cartes "En cours" font 300x165
                    estimatedItemWidth: 300,
                    estimatedItemHeight: 165,
                    // Pas d’enrichissement pour “En cours” (local-only), donc pas de callback.
                    items: <Widget>[
                      ...state.cwMovies.map(
                        (m) => ContinueWatchingCard.movie(
                          title: m.title.value,
                          poster: (m.backdrop ?? m.poster).toString(),
                          year: m.releaseYear?.toString() ?? '',
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
                    ].take(10).toList(),
                  ),
                ),

              // 32 px après "En cours"
              if (state.cwMovies.isNotEmpty || state.cwShows.isNotEmpty)
                const SliverToBoxAdapter(child: SizedBox(height: _sectionGap)),

              if (state.iptvLists.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Text(
                      'Aucune source IPTV active. Ajoutez une source dans Paramètres pour voir vos catégories.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),

              // ===== Sections IPTV ===== (enrichissement à la volée)
              for (final entry in state.iptvLists.entries) ...[
                SliverToBoxAdapter(
                  child: MoviItemsList(
                    title: _displayCategoryTitle(
                      entry.key,
                    ), // ← étiquette propre
                    itemSpacing: _itemSpacing,
                    estimatedItemWidth: _mediaCardWidth,
                    // Hauteur totale carte = poster (225) + titre (≈20) + marge (12)
                    // → 225 + 12 + 20 ≈ 257 ; on sécurise à 270 pour éviter overflow.
                    estimatedItemHeight: 270,
                    items: [
                      ...entry.value.take(9).map((r) {
                        final media = MoviMedia(
                          id: r.id,
                          title: r.title.value,
                          poster: r.poster,
                          year: r.year,
                          rating: r.rating,
                          type: r.type == ContentType.series
                              ? MoviMediaType.series
                              : MoviMediaType.movie,
                        );
                        return MoviMediaCard(media: media);
                      }),
                      SeeAllCard(
                        title: _displayCategoryTitle(entry.key),
                        categoryKey: entry.key,
                        width: _mediaCardWidth,
                        posterHeight: 225,
                        onTap: (args) => context.push('/category', extra: args),
                      ),
                    ],
                  ),
                ),
                // 32 px entre *chaque* section MoviItemsList IPTV
                const SliverToBoxAdapter(child: SizedBox(height: _sectionGap)),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ],
    );
  }
}

// _ViewportReq supprimé — l’UI n’émet plus de fenêtres de viewport pour enrichir.

class _HeroEmptyBanner extends StatelessWidget {
  const _HeroEmptyBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: const [
          SizedBox(height: 180),
          Text('Aucune tendance disponible', textAlign: TextAlign.center),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}
