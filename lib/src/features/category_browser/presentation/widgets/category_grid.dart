import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/utils/navigation_helpers.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/presentation/router/content_route_args.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';

class CategoryGrid extends ConsumerWidget {
  const CategoryGrid({
    super.key,
    required this.items,
    required this.backFocusNode,
    required this.firstItemFocusNode,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
  });

  final List<ContentReference> items;
  final FocusNode backFocusNode;
  final FocusNode firstItemFocusNode;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        MoviMediaGrid(
          itemCount: items.length,
          firstItemFocusNode: firstItemFocusNode,
          onExitUp: () {
            backFocusNode.requestFocus();
            return true;
          },
          onExitDown: () {
            if (hasMore && !isLoadingMore) {
              onLoadMore?.call();
            }
            return true;
          },
          itemBuilder: (context, index, focusNode, cardWidth, posterHeight) {
            final reference = items[index];
            final media = MoviMedia(
              id: reference.id,
              title: reference.title.value,
              poster: reference.poster,
              year: reference.year,
              rating: reference.rating,
              type: reference.type == ContentType.series
                  ? MoviMediaType.series
                  : MoviMediaType.movie,
            );

            return MoviMediaCard(
              media: media,
              width: cardWidth,
              height: posterHeight,
              focusNode: focusNode,
              onTap: (selectedMedia) {
                if (selectedMedia.type == MoviMediaType.movie) {
                  unawaited(
                    navigateToMovieDetail(
                      context,
                      ref,
                      ContentRouteArgs.movie(selectedMedia.id),
                    ),
                  );
                  return;
                }
                unawaited(
                  navigateToTvDetail(
                    context,
                    ref,
                    ContentRouteArgs.series(selectedMedia.id),
                  ),
                );
              },
            );
          },
        ),
        if (isLoadingMore) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        ],
      ],
    );
  }
}
