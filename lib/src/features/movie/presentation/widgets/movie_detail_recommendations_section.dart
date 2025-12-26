import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/utils/navigation_helpers.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/src/shared/presentation/router/content_route_args.dart';

class MovieDetailRecommendationsSection extends ConsumerWidget {
  const MovieDetailRecommendationsSection({super.key, required this.items});
  final List<MoviMedia> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              onTap: (mm) => navigateToMovieDetail(
                context,
                ref,
                ContentRouteArgs.movie(mm.id),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
