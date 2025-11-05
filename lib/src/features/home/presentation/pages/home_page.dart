import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/utils.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  List<_QuickLink> get _quickLinks => const [
        _QuickLink('Recherche', AppRouteNames.search),
        _QuickLink('Bibliothèque', AppRouteNames.library),
        _QuickLink('Paramètres', AppRouteNames.settings),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accueil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenue sur MOVI',
                style: context.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Retrouvez rapidement vos films, séries et artistes favoris.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: _quickLinks
                    .map(
                      (item) => FilledButton.tonal(
                        onPressed: () => context.push(item.route),
                        child: Text(item.label),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              _HomeSection(
                title: 'Continuer le visionnage',
                child: _PosterStrip(
                  titles: MockData.continueWatching,
                  onTap: () => context.push(AppRouteNames.movie),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              _HomeSection(
                title: 'À la une cette semaine',
                child: _PosterStrip(
                  titles: MockData.featuredSeries,
                  onTap: () => context.push(AppRouteNames.tv),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              _HomeSection(
                title: 'Suggestions de playlists',
                child: _PosterStrip(
                  titles: MockData.playlists,
                  aspectRatio: 1.2,
                  onTap: () => context.push(AppRouteNames.playlist),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeSection extends StatelessWidget {
  const _HomeSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

class _PosterStrip extends StatelessWidget {
  const _PosterStrip({
    required this.titles,
    required this.onTap,
    this.aspectRatio = 0.7,
  });

  final List<String> titles;
  final double aspectRatio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: titles.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) => AspectRatio(
          aspectRatio: aspectRatio,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: context.colorScheme.surfaceContainerHighest,
              ),
              child: Center(
                child: Text(
                  titles[index],
                  textAlign: TextAlign.center,
                  style: context.textTheme.titleMedium,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickLink {
  const _QuickLink(this.label, this.route);

  final String label;
  final String route;
}
