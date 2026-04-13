import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/utils/navigation_helpers.dart';
import 'package:movi/src/core/widgets/movi_items_list.dart';
import 'package:movi/src/core/widgets/movi_media_card.dart';
import 'package:movi/src/core/widgets/movi_see_all_card.dart';
import 'package:movi/src/features/category_browser/presentation/models/category_args.dart';
import 'package:movi/src/features/home/presentation/widgets/home_first_section_transition.dart';
import 'package:movi/src/features/home/presentation/widgets/home_layout_constants.dart';
import 'package:movi/src/features/home/presentation/widgets/home_loading_skeleton.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/presentation/router/content_route_args.dart';

/// Utilitaire pour extraire le titre de catégorie depuis une clé formatée "serveur/catégorie".
String displayCategoryTitle(String raw) {
  final idx = raw.indexOf('/');
  return (idx >= 0 && idx < raw.length - 1) ? raw.substring(idx + 1) : raw;
}

/// Section affichant une catégorie IPTV avec ses items.
class HomeIptvSection extends ConsumerWidget {
  const HomeIptvSection({
    super.key,
    required this.categoryTitle,
    required this.items,
    this.applyHeroTransition = false,
  });

  final String categoryTitle;
  final List<ContentReference> items;
  final bool applyHeroTransition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayTitle = displayCategoryTitle(categoryTitle);
    final screenType = ScreenTypeResolver.instance.resolve(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height,
    );
    final itemLimit = switch (screenType) {
      ScreenType.mobile => HomeLayoutConstants.iptvSectionMobileLimit,
      ScreenType.tablet => HomeLayoutConstants.iptvSectionTabletLimit,
      ScreenType.desktop ||
      ScreenType.tv => HomeLayoutConstants.iptvSectionDesktopLimit,
    };

    return HomeFirstSectionTransition(
      enabled: applyHeroTransition,
      child: MoviItemsList(
        title: displayTitle,
        itemSpacing: HomeLayoutConstants.itemSpacing,
        estimatedItemWidth: HomeLayoutConstants.mediaCardWidth,
        estimatedItemHeight: HomeLayoutConstants.mediaCardHeight,
        horizontalFocusAlignment: 0.18,
        items: [
          ...items.take(itemLimit).map((r) => _buildMediaCard(context, ref, r)),
          SeeAllCard(
            title: displayTitle,
            width: HomeLayoutConstants.mediaCardWidth,
            posterHeight: HomeLayoutConstants.mediaCardPosterHeight,
            onTap: () {
              context.push(
                '/category',
                extra: CategoryPageArgs(
                  title: displayTitle,
                  categoryKey: categoryTitle,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCard(
    BuildContext context,
    WidgetRef ref,
    ContentReference item,
  ) {
    final media = MoviMedia(
      id: item.id,
      title: item.title.value,
      poster: item.poster,
      year: item.year,
      rating: item.rating,
      type: item.type == ContentType.series
          ? MoviMediaType.series
          : MoviMediaType.movie,
    );

    return MoviMediaCard(
      media: media,
      onTap: (m) async {
        final routeArgs = m.type == MoviMediaType.movie
            ? ContentRouteArgs.movie(m.id)
            : ContentRouteArgs.series(m.id);
        if (m.type == MoviMediaType.movie) {
          await navigateToMovieDetail(
            context,
            ref,
            routeArgs,
            originRegionId: AppFocusRegionId.homePrimary,
            fallbackRegionId: AppFocusRegionId.homePrimary,
          );
        } else {
          await navigateToTvDetail(
            context,
            ref,
            routeArgs,
            originRegionId: AppFocusRegionId.homePrimary,
            fallbackRegionId: AppFocusRegionId.homePrimary,
          );
        }
      },
    );
  }
}

/// Widget affichant un message quand aucune source IPTV n'est disponible.
class HomeNoIptvSourcesMessage extends StatelessWidget {
  const HomeNoIptvSourcesMessage({super.key, this.applyHeroTransition = false});

  final bool applyHeroTransition;

  @override
  Widget build(BuildContext context) {
    return HomeFirstSectionTransition(
      enabled: applyHeroTransition,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Text(
          AppLocalizations.of(context)!.homeNoIptvSources,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

/// Widget affichant des skeletons de chargement pour les sections IPTV.
class HomeIptvLoadingSections extends StatelessWidget {
  const HomeIptvLoadingSections({super.key, this.applyHeroTransition = false});

  final bool applyHeroTransition;

  @override
  Widget build(BuildContext context) {
    final screenType = ScreenTypeResolver.instance.resolve(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height,
    );
    final itemLimit = switch (screenType) {
      ScreenType.mobile => HomeLayoutConstants.iptvSectionMobileLimit,
      ScreenType.tablet => HomeLayoutConstants.iptvSectionTabletLimit,
      ScreenType.desktop ||
      ScreenType.tv => HomeLayoutConstants.iptvSectionDesktopLimit,
    };

    return HomeFirstSectionTransition(
      enabled: applyHeroTransition,
      child: Column(
        children: [
          MoviItemsList(
            title: '',
            itemSpacing: HomeLayoutConstants.itemSpacing,
            estimatedItemWidth: HomeLayoutConstants.mediaCardWidth,
            estimatedItemHeight: HomeLayoutConstants.mediaCardHeight,
            horizontalFocusAlignment: 0.18,
            items: List.generate(itemLimit, (_) => const HomeLoadingSkeleton()),
          ),
          const SizedBox(height: HomeLayoutConstants.sectionGap),
          MoviItemsList(
            title: '',
            itemSpacing: HomeLayoutConstants.itemSpacing,
            estimatedItemWidth: HomeLayoutConstants.mediaCardWidth,
            estimatedItemHeight: HomeLayoutConstants.mediaCardHeight,
            horizontalFocusAlignment: 0.18,
            items: List.generate(itemLimit, (_) => const HomeLoadingSkeleton()),
          ),
          const SizedBox(height: HomeLayoutConstants.sectionGap),
        ],
      ),
    );
  }
}
