import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/features/home/presentation/widgets/home_hero_carousel.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

/// Section affichant le hero carousel ou un message si vide.
class HomeHeroSection extends ConsumerWidget {
  const HomeHeroSection({
    super.key,
    required this.heroItems,
    required this.onLoadingChanged,
  });

  final List<ContentReference> heroItems;
  final ValueChanged<bool> onLoadingChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(currentLanguageCodeProvider);

    if (heroItems.isEmpty) {
      return const SliverToBoxAdapter(child: _HeroEmptyBanner());
    }

    return SliverToBoxAdapter(
      child: HomeHeroCarousel(
        key: ValueKey(lang),
        items: heroItems.take(10).toList(growable: false),
        onLoadingChanged: onLoadingChanged,
      ),
    );
  }
}

/// Widget affichant un message quand aucun hero n'est disponible.
class _HeroEmptyBanner extends StatelessWidget {
  const _HeroEmptyBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: 180),
          Text(
            AppLocalizations.of(context)!.homeNoTrends,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
