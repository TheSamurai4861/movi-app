// lib/src/features/category_browser/presentation/widgets/category_grid.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/core/utils/navigation_helpers.dart';
import 'package:movi/src/shared/presentation/router/content_route_args.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class CategoryGrid extends ConsumerStatefulWidget {
  const CategoryGrid({
    super.key,
    required this.items,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
  });

  final List<ContentReference> items;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;

  @override
  ConsumerState<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends ConsumerState<CategoryGrid> {
  static const double _pageHorizontalPadding = 20;
  static const double _posterAspectRatio = 225 / 150;
  static const double _cardChromeHeight = MoviMediaCard.listHeight - 225;
  static const double _minLargeCardWidth = 112;
  final ScrollController _scrollController = ScrollController();
  late List<FocusNode> _itemFocusNodes = _buildItemFocusNodes(
    widget.items.length,
  );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  List<FocusNode> _buildItemFocusNodes(int count) {
    return List<FocusNode>.generate(
      count,
      (index) => FocusNode(debugLabel: 'CategoryGridItem-$index'),
      growable: false,
    );
  }

  void _disposeItemFocusNodes() {
    for (final node in _itemFocusNodes) {
      node.dispose();
    }
  }

  @override
  void didUpdateWidget(covariant CategoryGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _disposeItemFocusNodes();
      _itemFocusNodes = _buildItemFocusNodes(widget.items.length);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _disposeItemFocusNodes();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        widget.hasMore &&
        !widget.isLoadingMore &&
        widget.onLoadMore != null) {
      widget.onLoadMore!();
    }
  }

  static const double cardWidth = 150;
  static const double gridGapH = 24; // gap horizontal à 24px
  static const double gridGapV = 16; // gap vertical inchangé
  static const double focusBleed = 12; // espace pour le scale/glow du focus

  ScreenType _screenTypeFor(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return ScreenTypeResolver.instance.resolve(size.width, size.height);
  }

  bool _isLargeScreen(BuildContext context) {
    final screenType = _screenTypeFor(context);
    return screenType == ScreenType.desktop || screenType == ScreenType.tv;
  }

  double _slotWidthFor(double availableWidth, int crossAxisCount) {
    return (availableWidth - (gridGapH * (crossAxisCount - 1))) /
        crossAxisCount;
  }

  KeyEventResult _handleGridDirection(
    int index,
    int crossAxisCount,
    KeyEvent event,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    int? targetIndex;

    if (key == LogicalKeyboardKey.arrowLeft) {
      if (index % crossAxisCount == 0) {
        return KeyEventResult.handled;
      }
      targetIndex = index - 1;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      final isLastColumn = (index % crossAxisCount) == crossAxisCount - 1;
      if (isLastColumn || index + 1 >= widget.items.length) {
        return KeyEventResult.handled;
      }
      targetIndex = index + 1;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      if (index - crossAxisCount < 0) {
        return KeyEventResult.handled;
      }
      targetIndex = index - crossAxisCount;
    } else if (key == LogicalKeyboardKey.arrowDown) {
      if (index + crossAxisCount >= widget.items.length) {
        return KeyEventResult.handled;
      }
      targetIndex = index + crossAxisCount;
    }

    if (targetIndex == null) return KeyEventResult.ignored;
    _itemFocusNodes[targetIndex].requestFocus();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final baseLayoutCardWidth = cardWidth + focusBleed;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth - (_pageHorizontalPadding * 2);
        final isLargeScreen = _isLargeScreen(context);

        // Calculer dynamiquement le nombre de colonnes en fonction de la largeur,
        // tout en gardant une largeur de carte raisonnable.
        // Permet 1 colonne sur très petits écrans (< 300px).
        int crossAxisCount = (availableWidth / (baseLayoutCardWidth + gridGapH))
            .floor()
            .clamp(1, 6);
        // Autoriser 1 colonne si l'écran est très étroit (< 300px)
        if (crossAxisCount < 1) {
          crossAxisCount = 1;
        } else if (crossAxisCount == 1 && availableWidth >= 300) {
          crossAxisCount = 2;
        }

        if (isLargeScreen) {
          crossAxisCount += 2;
          while (crossAxisCount > 1 &&
              (_slotWidthFor(availableWidth, crossAxisCount) - focusBleed) <
                  _minLargeCardWidth) {
            crossAxisCount--;
          }
        }

        final layoutCardWidth = _slotWidthFor(availableWidth, crossAxisCount);
        final resolvedCardWidth = layoutCardWidth - focusBleed;
        final resolvedPosterHeight = resolvedCardWidth * _posterAspectRatio;
        final resolvedCardHeight = resolvedPosterHeight + _cardChromeHeight;
        final layoutItemHeight = resolvedCardHeight + focusBleed;
        final gridWidth =
            (layoutCardWidth * crossAxisCount) +
            gridGapH * (crossAxisCount - 1);

        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _pageHorizontalPadding,
            ),
            child: SizedBox(
              width: gridWidth,
              child: GridView.builder(
                controller: _scrollController,
                clipBehavior: Clip.none,
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: gridGapV,
                  crossAxisSpacing: gridGapH,
                  childAspectRatio: layoutCardWidth / layoutItemHeight,
                ),
                itemCount:
                    widget.items.length +
                    (widget.isLoadingMore ? 1 : 0) +
                    (widget.hasMore && !widget.isLoadingMore ? 0 : 0),
                itemBuilder: (context, index) {
                  // Afficher l'indicateur de chargement en bas si on charge plus
                  if (index == widget.items.length && widget.isLoadingMore) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final r = widget.items[index];
                  final media = MoviMedia(
                    id: r.id,
                    title: r.title.value,
                    poster: r.poster,
                    year: r.year,
                    rating: r.rating,
                    type: r.type == ContentType.series
                        ? MoviMediaType.series
                        : MoviMediaType.movie,
                  );
                  return Focus(
                    canRequestFocus: false,
                    onKeyEvent: (_, event) =>
                        _handleGridDirection(index, crossAxisCount, event),
                    child: Center(
                      child: MoviMediaCard(
                        media: media,
                        width: resolvedCardWidth,
                        height: resolvedPosterHeight,
                        focusNode: _itemFocusNodes[index],
                        onTap: (m) {
                          if (m.type == MoviMediaType.movie) {
                            unawaited(
                              navigateToMovieDetail(
                                context,
                                ref,
                                ContentRouteArgs.movie(m.id),
                              ),
                            );
                          } else {
                            unawaited(
                              navigateToTvDetail(
                                context,
                                ref,
                                ContentRouteArgs.series(m.id),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
