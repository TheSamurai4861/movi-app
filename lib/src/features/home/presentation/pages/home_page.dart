// lib/src/features/home/presentation/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'dart:async';

import '../providers/home_providers.dart' as hp;

import '../../../../core/utils/utils.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../../../core/widgets/movi_bottom_nav_bar.dart';
import '../../../../core/widgets/movi_items_list.dart';
import '../../../../core/widgets/movi_media_card.dart';
import '../../../../core/models/movi_media.dart';
import '../widgets/home_hero_section.dart';
import '../widgets/continue_watching_card.dart';
// logging_service n'est plus utilisé sur la page d'accueil
// overlay_splash supprimé de la page d'accueil

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _fadeDuration = Duration(milliseconds: 500);
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
  static const double _sectionGap = 32; // espace VERTICAL entre sections MoviItemsList

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
                child: HomeHeroSection(
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
                    items: ([
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
                    ]).take(10).toList(),
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
                    items: entry.value.take(10).map((r) {
                      // Poster (TMDB ou fallback IPTV déjà fourni par le repo)
                      final poster = r.poster?.toString() ?? '';
                      // Désactiver toute pill: ne pas afficher année/score pour les listes
                      const String yearStr = '';
                      const String ratingStr = '';

                      final media = MoviMedia(
                        id: r.id,
                        title: r.title.value,
                        poster: poster,
                        year: yearStr, // <-- String non nulle
                        rating: ratingStr, // <-- String non nulle
                        type: r.type == ContentType.series
                            ? MoviMediaType.series
                            : MoviMediaType.movie,
                      );
                      return MoviMediaCard(media: media);
                    }).toList(),
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
