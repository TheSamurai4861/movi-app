// lib/src/features/category_browser/presentation/widgets/category_grid.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
  static const double posterHeight = 226;
  static const double textHeight = 20; // hauteur approximative du titre
  static const double textMarginTop = 12; // marge entre affiche et texte
  static const double gridGapH = 24; // gap horizontal à 24px
  static const double gridGapV = 16; // gap vertical inchangé

  @override
  Widget build(BuildContext context) {
    final double itemHeight = posterHeight + textMarginTop + textHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        // Calculer dynamiquement le nombre de colonnes en fonction de la largeur,
        // tout en gardant une largeur de carte raisonnable.
        // Permet 1 colonne sur très petits écrans (< 300px).
        int crossAxisCount = (availableWidth / (cardWidth + gridGapH))
            .floor()
            .clamp(1, 6);
        // Autoriser 1 colonne si l'écran est très étroit (< 300px)
        if (crossAxisCount < 1) {
          crossAxisCount = 1;
        } else if (crossAxisCount == 1 && availableWidth >= 300) {
          crossAxisCount = 2;
        }

        final gridWidth =
            (cardWidth * crossAxisCount) + gridGapH * (crossAxisCount - 1);

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: gridWidth,
            child: GridView.builder(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: gridGapV,
                crossAxisSpacing: gridGapH,
                childAspectRatio: cardWidth / itemHeight,
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
                return MoviMediaCard(
                  media: media,
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
                );
              },
            ),
          ),
        );
      },
    );
  }
}
