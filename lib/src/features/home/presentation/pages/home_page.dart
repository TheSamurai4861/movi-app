// lib/src/features/home/presentation/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

import '../providers/home_providers.dart' as hp;

import '../../../../core/utils/utils.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../../../core/widgets/movi_bottom_nav_bar.dart';
import '../../../../core/widgets/movi_items_list.dart';
import '../../../../core/widgets/movi_media_card.dart';
import '../../../../core/models/movi_media.dart';
import '../widgets/home_hero_section.dart';
import '../widgets/continue_watching_card.dart';

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

class _HomeContent extends ConsumerStatefulWidget {
  const _HomeContent({super.key});

  @override
  ConsumerState<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<_HomeContent> {
  // --- Mémo anti-doublons par catégorie (évite les relances inutiles)
  final Map<String, _ViewportReq> _lastReq = {};

  bool _isScheduled = false;
  void _postFrame(VoidCallback fn) {
    if (_isScheduled) return;
    _isScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fn();
      _isScheduled = false;
    });
  }

  static const double _mediaCardWidth =
      150; // doit rester aligné avec MoviMediaCard par défaut
  static const double _itemSpacing = 32; // espace horizontal entre items
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

          // On rend le vrai hero avec le state (évite les rebuilds visibles)
          SliverToBoxAdapter(
            child: HomeHeroSection(
              movie: state.hero.isNotEmpty ? state.hero.first : null,
            ),
          ),

          // Marge après le hero (libre, non concernée par "32px entre MoviItemsList")
          const SliverToBoxAdapter(child: SizedBox(height: 54)),

          // ===== Section "En cours" =====
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
                ],
              ),
            ),

          // 32 px après "En cours"
          if (state.cwMovies.isNotEmpty || state.cwShows.isNotEmpty)
            const SliverToBoxAdapter(child: SizedBox(height: _sectionGap)),

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

          // ===== Sections IPTV ===== (enrichissement à la volée)
          for (final entry in state.iptvLists.entries) ...[
            SliverToBoxAdapter(
              child: MoviItemsList(
                title: _displayCategoryTitle(entry.key), // ← étiquette propre
                itemSpacing: _itemSpacing,
                estimatedItemWidth: _mediaCardWidth,
                // → Notifie le contrôleur d’enrichir le batch visible (+preload)
                onViewportChanged: (start, count) {
                  // On ajoute un petit buffer pour éviter de recalculer à chaque pixel
                  final buffered = _ViewportReq(start, count + 8);
                  final last = _lastReq[entry.key];

                  // Si la nouvelle zone est incluse dans la précédente → on ne relance pas
                  if (last != null && last.contains(buffered)) return;

                  // Mémorise la nouvelle plage puis déclenche en post-frame (throttle)
                  _lastReq[entry.key] = buffered;
                  _postFrame(() {
                    controller.enrichCategoryBatch(
                      entry.key,
                      buffered.start,
                      buffered.count,
                    );
                  });
                },

                items: entry.value.take(40).map((r) {
                  // Poster (TMDB ou fallback IPTV déjà fourni par le repo)
                  final poster = r.poster?.toString() ?? '';

                  // Fournir des Strings non nulles pour respecter la signature de MoviMedia
                  final yearStr = r.year != null ? r.year!.toString() : '';
                  final ratingStr = r.rating != null
                      ? (r.rating! >= 10 ? '10' : r.rating!.toStringAsFixed(1))
                      : '';

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
    );
  }
}

class _ViewportReq {
  final int start;
  final int count;
  const _ViewportReq(this.start, this.count);

  // Retourne true si `other` est entièrement inclus dans cette plage
  bool contains(_ViewportReq other) {
    final end = start + count;
    final oEnd = other.start + other.count;
    return other.start >= start && oEnd <= end;
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
