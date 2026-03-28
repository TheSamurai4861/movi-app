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
    this.horizontalPadding = 20,
  });

  final SagaSummary sagaLink;
  final String? currentMovieId;
  final double horizontalPadding;

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
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: horizontalPadding,
                end: horizontalPadding,
              ),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      '${AppLocalizations.of(context)!.searchSagasTitle} ${sagaLink.title.display}',
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  MoviFocusableAction(
                    onPressed: () {
                      context.push(
                        AppRouteNames.sagaDetail,
                        extra: sagaLink.id.value,
                      );
                    },
                    semanticLabel: 'Voir la page de la saga',
                    builder: (context, state) {
                      return MoviFocusFrame(
                        scale: state.focused ? 1.03 : 1,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        borderRadius: BorderRadius.circular(999),
                        backgroundColor: state.focused
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                        child: Text(
                          'Voir la page',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            MoviItemsList(
              title: '',
              hideHeader: true,
              estimatedItemWidth: 150,
              estimatedItemHeight: MoviMediaCard.listHeight,
              titlePadding: 0,
              horizontalPadding: EdgeInsetsDirectional.only(
                start: horizontalPadding,
                end: horizontalPadding,
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
