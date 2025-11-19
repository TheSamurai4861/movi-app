import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/models/models.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/widgets/movi_items_list.dart';
import 'package:movi/src/core/widgets/movi_media_card.dart';
import 'package:movi/src/core/widgets/movi_see_all_card.dart';
import 'package:movi/src/features/home/presentation/widgets/home_layout_constants.dart';
import 'package:movi/src/features/home/presentation/widgets/home_loading_skeleton.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

/// Utilitaire pour extraire le titre de catégorie depuis une clé formatée "serveur/catégorie".
String displayCategoryTitle(String raw) {
  final idx = raw.indexOf('/');
  return (idx >= 0 && idx < raw.length - 1) ? raw.substring(idx + 1) : raw;
}

/// Section affichant une catégorie IPTV avec ses items.
class HomeIptvSection extends StatelessWidget {
  const HomeIptvSection({
    super.key,
    required this.categoryTitle,
    required this.items,
  });

  final String categoryTitle;
  final List<ContentReference> items;

  @override
  Widget build(BuildContext context) {
    final displayTitle = displayCategoryTitle(categoryTitle);
    return MoviItemsList(
      title: displayTitle,
      itemSpacing: HomeLayoutConstants.itemSpacing,
      estimatedItemWidth: HomeLayoutConstants.mediaCardWidth,
      estimatedItemHeight: HomeLayoutConstants.mediaCardHeight,
      items: [
        ...items
            .take(HomeLayoutConstants.iptvSectionLimit)
            .map((r) => _buildMediaCard(context, r)),
        SeeAllCard(
          title: displayTitle,
          categoryKey: categoryTitle,
          width: HomeLayoutConstants.mediaCardWidth,
          posterHeight: HomeLayoutConstants.mediaCardPosterHeight,
          onTap: (args) => context.push('/category', extra: args),
        ),
      ],
    );
  }

  Widget _buildMediaCard(BuildContext context, ContentReference ref) {
    final media = MoviMedia(
      id: ref.id,
      title: ref.title.value,
      poster: ref.poster,
      year: ref.year,
      rating: ref.rating,
      type: ref.type == ContentType.series
          ? MoviMediaType.series
          : MoviMediaType.movie,
    );

    return MoviMediaCard(
      media: media,
      onTap: (m) {
        final route = m.type == MoviMediaType.movie
            ? AppRouteNames.movie
            : AppRouteNames.tv;
        context.push(route, extra: m);
      },
    );
  }
}

/// Widget affichant un message quand aucune source IPTV n'est disponible.
class HomeNoIptvSourcesMessage extends StatelessWidget {
  const HomeNoIptvSourcesMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Text(
        AppLocalizations.of(context)!.homeNoIptvSources,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

/// Widget affichant des skeletons de chargement pour les sections IPTV.
class HomeIptvLoadingSections extends StatelessWidget {
  const HomeIptvLoadingSections({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MoviItemsList(
          title: '',
          itemSpacing: HomeLayoutConstants.itemSpacing,
          estimatedItemWidth: HomeLayoutConstants.mediaCardWidth,
          estimatedItemHeight: HomeLayoutConstants.mediaCardHeight,
          items: List.generate(
            HomeLayoutConstants.iptvSectionLimit,
            (_) => const HomeLoadingSkeleton(),
          ),
        ),
        const SizedBox(height: HomeLayoutConstants.sectionGap),
        MoviItemsList(
          title: '',
          itemSpacing: HomeLayoutConstants.itemSpacing,
          estimatedItemWidth: HomeLayoutConstants.mediaCardWidth,
          estimatedItemHeight: HomeLayoutConstants.mediaCardHeight,
          items: List.generate(
            HomeLayoutConstants.iptvSectionLimit,
            (_) => const HomeLoadingSkeleton(),
          ),
        ),
        const SizedBox(height: HomeLayoutConstants.sectionGap),
      ],
    );
  }
}
