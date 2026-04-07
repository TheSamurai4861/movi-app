import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
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
    required this.loadMoreFocusNode,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
  });

  final List<ContentReference> items;
  final FocusNode backFocusNode;
  final FocusNode firstItemFocusNode;
  final FocusNode loadMoreFocusNode;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        MoviMediaGrid(
          itemCount: items.length,
          firstItemFocusNode: firstItemFocusNode,
          footerFocusNode: hasMore ? loadMoreFocusNode : null,
          onExitUp: () {
            backFocusNode.requestFocus();
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
        if (hasMore) ...[
          const SizedBox(height: 20),
          Focus(
            canRequestFocus: false,
            onKeyEvent: (_, event) {
              if (event is! KeyDownEvent) {
                return KeyEventResult.ignored;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                firstItemFocusNode.requestFocus();
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                  event.logicalKey == LogicalKeyboardKey.arrowRight ||
                  event.logicalKey == LogicalKeyboardKey.arrowDown) {
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: MoviPrimaryButton(
                  label: l10n.actionLoadMore,
                  focusNode: loadMoreFocusNode,
                  expand: false,
                  loading: isLoadingMore,
                  onPressed: isLoadingMore ? null : onLoadMore,
                ),
              ),
            ),
          ),
        ] else if (isLoadingMore) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        ],
      ],
    );
  }
}
