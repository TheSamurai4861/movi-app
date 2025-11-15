// lib/src/features/category_browser/presentation/widgets/category_grid.dart
import 'package:flutter/material.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/core/models/models.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key, required this.items});

  final List<ContentReference> items;

  static const double cardWidth = 150;
  static const double posterHeight = 226;
  static const double textHeight = 20; // hauteur approximative du titre
  static const double textMarginTop = 12; // marge entre affiche et texte
  static const double gridGapH = 24; // gap horizontal à 24px
  static const double gridGapV = 16; // gap vertical inchangé

  @override
  Widget build(BuildContext context) {
    final double gridWidth = (cardWidth * 2) + gridGapH; // 2 affiches + gap
    final double itemHeight = posterHeight + textMarginTop + textHeight;

    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: gridWidth,
        child: GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: gridGapV,
            crossAxisSpacing: gridGapH,
            childAspectRatio: cardWidth / itemHeight,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final r = items[index];
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
            return MoviMediaCard(media: media);
          },
        ),
      ),
    );
  }
}
