import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/utils/navigation_helpers.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/features/movie/presentation/providers/movie_detail_providers.dart';
import 'package:movi/src/shared/presentation/router/content_route_args.dart';

class MovieDetailSagaSection extends ConsumerWidget {
  const MovieDetailSagaSection({
    super.key,
    required this.sagaLink,
    required this.currentMovieId,
  });

  final SagaSummary sagaLink;
  final String? currentMovieId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sagaMoviesAsync = ref.watch(sagaMoviesProvider(sagaLink));
    return sagaMoviesAsync.when(
      data: (sagaMovies) {
        if (sagaMovies.isEmpty) return const SizedBox.shrink();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MoviItemsList(
              title:
                  '${AppLocalizations.of(context)!.searchSagasTitle} ${sagaLink.title.display}',
              estimatedItemWidth: 150,
              estimatedItemHeight: 258,
              titlePadding: 20,
              horizontalPadding: const EdgeInsetsDirectional.only(
                start: 20,
                end: 0,
              ),
              action: Padding(
                padding: const EdgeInsetsDirectional.only(end: 20),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    context.push(
                      AppRouteNames.sagaDetail,
                      extra: sagaLink.id.value,
                    );
                  },
                  child: Text(
                    'Voir la page',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              items: sagaMovies
                  .map(
                    (m) => MoviMediaCard(
                      media: m,
                      heroTag: 'saga_${m.id}',
                      highlightBorder: m.id == currentMovieId,
                      onTap: (mm) => navigateToMovieDetail(
                        context,
                        ref,
                        ContentRouteArgs.movie(mm.id),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
