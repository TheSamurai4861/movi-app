import 'package:flutter/material.dart';

/// Scroll vertical qui ne construit chaque section que lorsqu'elle approche du viewport.
class MoviLazySectionScroll extends StatelessWidget {
  const MoviLazySectionScroll({
    super.key,
    required this.sectionCount,
    required this.sectionBuilder,
    this.controller,
    this.padding = EdgeInsets.zero,
    this.cacheExtent,
    this.keepAliveSectionIndices = const <int>{},
  });

  final int sectionCount;
  final Widget Function(BuildContext context, int index) sectionBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry padding;
  final double? cacheExtent;

  /// Indices de sections à garder en mémoire (ex. en-tête avec champ texte).
  final Set<int> keepAliveSectionIndices;

  @override
  Widget build(BuildContext context) {
    if (sectionCount <= 0) {
      return const SizedBox.shrink();
    }

    return CustomScrollView(
      controller: controller,
      cacheExtent: cacheExtent ?? 480,
      slivers: [
        SliverPadding(
          padding: padding,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final section = sectionBuilder(context, index);
                if (keepAliveSectionIndices.contains(index)) {
                  return _KeepAliveSection(child: section);
                }
                return section;
              },
              childCount: sectionCount,
              addRepaintBoundaries: true,
            ),
          ),
        ),
      ],
    );
  }
}

class _KeepAliveSection extends StatefulWidget {
  const _KeepAliveSection({required this.child});

  final Widget child;

  @override
  State<_KeepAliveSection> createState() => _KeepAliveSectionState();
}

class _KeepAliveSectionState extends State<_KeepAliveSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
