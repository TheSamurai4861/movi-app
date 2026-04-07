import 'package:flutter/material.dart';
import 'package:movi/src/core/widgets/movi_subpage_back_title_header.dart';

class CategoryHeader extends StatelessWidget {
  const CategoryHeader({
    super.key,
    required this.title,
    this.onBack,
    this.backFocusNode,
  });

  final String title;
  final VoidCallback? onBack;
  final FocusNode? backFocusNode;

  @override
  Widget build(BuildContext context) {
    return MoviSubpageBackTitleHeader(
      title: title,
      onBack: onBack,
      focusNode: backFocusNode,
    );
  }
}
