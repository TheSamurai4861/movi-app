// lib/src/features/category_browser/presentation/widgets/category_header.dart
import 'package:flutter/material.dart';

import 'package:movi/src/core/widgets/movi_subpage_back_title_header.dart';

/// Même en-tête que la page résultats provider ([MoviSubpageBackTitleHeader]).
class CategoryHeader extends StatelessWidget {
  const CategoryHeader({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return MoviSubpageBackTitleHeader(
      title: title,
      onBack: onBack,
    );
  }
}
