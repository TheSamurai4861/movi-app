import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';

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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenue sur MOVI',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Retrouvez rapidement vos films, séries et artistes favoris.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _quickLinks
                    .map(
                      (item) => FilledButton.tonal(
                        onPressed: () => context.push(item.route),
                        child: Text(item.label),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 32),
              _HomeSection(
                title: 'Continuer le visionnage',
                child: _PosterStrip(
                  itemCount: 6,
                  onTap: () => context.push(AppRouteNames.movie),
                ),
              ),
              const SizedBox(height: 32),
              _HomeSection(
                title: 'À la une cette semaine',
                child: _PosterStrip(
                  itemCount: 5,
                  onTap: () => context.push(AppRouteNames.tv),
                ),
              ),
              const SizedBox(height: 32),
              _HomeSection(
                title: 'Suggestions de playlists',
                child: _PosterStrip(
                  itemCount: 4,
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
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class _PosterStrip extends StatelessWidget {
  const _PosterStrip({
    required this.itemCount,
    required this.onTap,
    this.aspectRatio = 0.7,
  });

  final int itemCount;
  final double aspectRatio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) => AspectRatio(
          aspectRatio: aspectRatio,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.surfaceVariant,
              ),
              child: Center(
                child: Text(
                  'Item ${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
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
