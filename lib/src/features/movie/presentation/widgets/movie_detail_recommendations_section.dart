import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/core/models/models.dart';

class MovieDetailRecommendationsSection extends StatelessWidget {
  const MovieDetailRecommendationsSection({super.key, required this.items});
  final List<MoviMedia> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return MoviItemsList(
      title: AppLocalizations.of(context)!.recommendationsTitle,
      estimatedItemWidth: 150,
      estimatedItemHeight: 258,
      titlePadding: 20,
      horizontalPadding: const EdgeInsetsDirectional.only(start: 20, end: 0),
      items: items
          .map(
            (m) => MoviMediaCard(
              media: m,
              heroTag: 'reco_${m.id}',
              onTap: (mm) => context.push(AppRouteNames.movie, extra: mm),
            ),
          )
          .toList(growable: false),
    );
  }
}
