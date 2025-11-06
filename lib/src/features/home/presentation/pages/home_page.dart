import 'package:flutter/material.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/utils/app_assets.dart';
import '../../../../core/widgets/movi_bottom_nav_bar.dart';
import '../../../../core/widgets/movi_favorite_button.dart';
import '../../../../core/mock/mock_home_content.dart';
import '../../../../core/widgets/movi_items_list.dart';
import '../../../../core/widgets/movi_media_card.dart';
import '../../../../core/widgets/movi_person_card.dart';
import '../../../../core/widgets/movi_pill.dart';
import '../../../../core/widgets/movi_primary_button.dart';

/// Écran réduit pour tester uniquement les boutons
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _fadeDuration = Duration(milliseconds: 300);
  static const _navBottomOffset = 40.0;

  bool _isHeroFavorite = false;
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

    final heroData = MockHomeContent.hero;
    final mediaCards = MockHomeContent.knownMovies
        .map<Widget>((media) => MoviMediaCard(media: media))
        .toList();
    final personCards = MockHomeContent.featuredPeople
        .map<Widget>((person) => MoviPersonCard(person: person))
        .toList();

    final pages = <Widget>[
      KeyedSubtree(
        key: const ValueKey('home'),
        child: _HomeContent(
          hero: heroData,
          mediaCards: mediaCards,
          personCards: personCards,
          bottomPadding: bottomPadding,
          isFavorite: _isHeroFavorite,
          onToggleFavorite: () => setState(() => _isHeroFavorite = !_isHeroFavorite),
        ),
      ),
      _NavPlaceholder(
        key: ValueKey('search'),
        title: 'Recherche',
        bottomPadding: bottomPadding,
      ),
      _NavPlaceholder(
        key: ValueKey('library'),
        title: 'Bibliothèque',
        bottomPadding: bottomPadding,
      ),
      _NavPlaceholder(
        key: ValueKey('settings'),
        title: 'Paramètres',
        bottomPadding: bottomPadding,
      ),
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
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
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

class _NavPlaceholder extends StatelessWidget {
  const _NavPlaceholder({
    required this.title,
    required this.bottomPadding,
    super.key,
  });

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
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.hero,
    required this.mediaCards,
    required this.personCards,
    required this.bottomPadding,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final HomeHeroData hero;
  final List<Widget> mediaCards;
  final List<Widget> personCards;
  final double bottomPadding;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HomeHeroSection(
            hero: hero,
            isFavorite: isFavorite,
            onToggleFavorite: onToggleFavorite,
          ),
          const SizedBox(height: 48),
          MoviItemsList(
            title: 'Films à (re)découvrir',
            items: mediaCards,
            subtitle: '(${mediaCards.length} résultats)',
          ),
          if (personCards.isNotEmpty) ...[
            const SizedBox(height: 32),
            MoviItemsList(
              title: 'Distribution',
              subtitle: '(${personCards.length} personnes)',
              items: personCards,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _HomeHeroSection extends StatelessWidget {
  const _HomeHeroSection({
    required this.hero,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final HomeHeroData hero;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final base = const Color(0xFF141414);
    final media = MediaQuery.of(context);

    return SizedBox(
      height: 650,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: _buildPosterImage(
              hero.backgroundImage,
              media.size.width,
              650,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    base.withOpacity(0.75),
                    base.withOpacity(0.15),
                  ],
                  stops: const [0.0, 0.6],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: 180,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          base.withOpacity(0.9),
                          base.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          base.withOpacity(0.7),
                          base.withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.7],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroInfoBlock(hero: hero),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: MoviPrimaryButton(
                        label: 'Regarder',
                        routeName: AppRouteNames.movie,
                        replace: false,
                        assetIcon: AppAssets.iconPlay,
                      ),
                    ),
                    const SizedBox(width: 16),
                    MoviFavoriteButton(
                      isFavorite: isFavorite,
                      onPressed: onToggleFavorite,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroInfoBlock extends StatelessWidget {
  const _HeroInfoBlock({required this.hero});

  final HomeHeroData hero;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final synopsisStyle = theme.textTheme.bodyMedium?.copyWith(
          fontSize: 16,
          color: Colors.white.withOpacity(0.85),
        ) ??
        const TextStyle(fontSize: 16, color: Colors.white70);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 100),
            child: _buildPosterImage(
              hero.logoImage,
              300,
              100,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              MoviPill(hero.media.year),
              MoviPill(hero.duration),
              MoviPill(
                hero.media.rating,
                trailingIcon: Image.asset(
                  AppAssets.iconStarFilled,
                  width: 18,
                  height: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          hero.synopsis,
          style: synopsisStyle,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.left,
        ),
      ],
    );
  }
}

Widget _buildPosterImage(String source, double width, double height,
    {BoxFit fit = BoxFit.cover}) {
  final fallback = Container(
    width: width,
    height: height,
    color: const Color(0xFF222222),
    child:
        const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 32)),
  );

  if (source.startsWith('http')) {
    return Image.network(
      source,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback,
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
    fit: fit,
    errorBuilder: (_, __, ___) => fallback,
  );
}
