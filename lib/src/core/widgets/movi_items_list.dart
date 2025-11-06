import 'package:flutter/material.dart';

/// Horizontal list section with a title aligned to the left edge.
///
/// Layout:
/// - Title (textTheme.titleMedium) with 20px inset from the left edge.
///   Optional subtitle aligned to the right, styled light grey.
/// - 16px spacing below the title.
/// - Horizontally scrollable list of cards separated by 16px, padded by 20px
///   on both sides so the first card aligns with the title.
class MoviItemsList extends StatelessWidget {
  const MoviItemsList({
    super.key,
    required this.title,
    required this.items,
    this.itemSpacing = 16,
    this.horizontalPadding = const EdgeInsets.symmetric(horizontal: 20),
    this.titlePadding = 20,
    this.subtitle,
  }) : assert(itemSpacing >= 0, 'itemSpacing must be non-negative');

  /// Section title displayed above the list.
  final String title;

  /// Optional secondary label displayed to the right of the title.
  final String? subtitle;

  /// Cards/widgets displayed horizontally.
  final List<Widget> items;

  /// Spacing between each card in the horizontal list.
  final double itemSpacing;

  /// Padding applied to the horizontal list.
  final EdgeInsetsGeometry horizontalPadding;

  /// Left padding applied to the title text.
  final double titlePadding;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: titlePadding, end: titlePadding),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFA6A6A6),
                      ) ??
                      const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFA6A6A6),
                      ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: horizontalPadding,
          child: Row(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i != items.length - 1)
                  SizedBox(width: itemSpacing),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
