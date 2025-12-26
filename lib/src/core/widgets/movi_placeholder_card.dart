import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;

enum PlaceholderType { person, movie, series }

/// Placeholder card with accent color background and centered logo.
class MoviPlaceholderCard extends ConsumerWidget {
  const MoviPlaceholderCard({
    super.key,
    required this.type,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.borderRadius,
  });

  final PlaceholderType type;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final BorderRadius? borderRadius;

  String _getIconAsset() {
    switch (type) {
      case PlaceholderType.person:
        return AppAssets.iconAppLogoSvg;
      case PlaceholderType.movie:
        return AppAssets.iconMovie;
      case PlaceholderType.series:
        return AppAssets.iconSerie;
    }
  }

  bool _isSvg() {
    return type == PlaceholderType.person;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(asp.currentAccentColorProvider);

    Widget container = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
      ),
      child: Align(
        alignment: alignment,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final effectiveWidth = width ?? constraints.maxWidth;
            final effectiveHeight = height ?? constraints.maxHeight;
            final iconSize =
                (effectiveWidth < effectiveHeight
                    ? effectiveWidth
                    : effectiveHeight) *
                0.4;

            if (_isSvg()) {
              return SvgPicture.asset(
                _getIconAsset(),
                width: iconSize,
                height: iconSize,
                colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
              );
            }

            return Image.asset(
              _getIconAsset(),
              width: iconSize,
              height: iconSize,
              color: Colors.white,
              fit: BoxFit.contain,
            );
          },
        ),
      ),
    );

    if (width == null || height == null) {
      container = SizedBox.expand(child: container);
    }

    return container;
  }
}
