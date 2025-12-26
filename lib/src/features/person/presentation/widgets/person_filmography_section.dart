import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/shared/presentation/router/content_route_args.dart';

/// Displays the filmography lists (movies and series), if available.
class PersonFilmographySection extends StatelessWidget {
  const PersonFilmographySection({
    super.key,
    required this.movies,
    required this.shows,
  });

  final List<MoviMedia> movies;
  final List<MoviMedia> shows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (movies.isNotEmpty) ...[
          MoviItemsList(
            title: AppLocalizations.of(context)!.personMoviesList,
            estimatedItemWidth: 150,
            estimatedItemHeight: 300,
            titlePadding: 0,
            horizontalPadding: EdgeInsets.zero,
            items: movies
                .map(
                  (media) => MoviMediaCard(
                    media: media,
                    onTap: (m) => context.push(
                      AppRouteNames.movie,
                      extra: ContentRouteArgs.movie(m.id),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
        if (shows.isNotEmpty) ...[
          MoviItemsList(
            title: AppLocalizations.of(context)!.personSeriesList,
            estimatedItemWidth: 150,
            estimatedItemHeight: 300,
            titlePadding: 0,
            horizontalPadding: EdgeInsets.zero,
            items: shows
                .map(
                  (media) => MoviMediaCard(
                    media: media,
                    onTap: (m) => context.push(
                      AppRouteNames.tv,
                      extra: ContentRouteArgs.series(m.id),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 32),
        ],
      ],
    );
  }
}
