import 'package:flutter/material.dart';

import 'package:movi/src/core/widgets/movi_asset_icon.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/core/widgets/movi_hero_gradients.dart';
import 'package:movi/src/core/widgets/movi_hero_scene.dart';

class MoviDetailHeroScene extends StatelessWidget {
  const MoviDetailHeroScene({
    super.key,
    required this.isWideLayout,
    required this.background,
    this.children = const <Widget>[],
    this.overlaySpec,
    this.mobileHeight = defaultMobileHeight,
    this.wideHeight = defaultWideHeight,
  });

  static const double defaultMobileHeight = 400;
  static const double defaultWideHeight = 520;

  final bool isWideLayout;
  final Widget background;
  final List<Widget> children;
  final MoviHeroOverlaySpec? overlaySpec;
  final double mobileHeight;
  final double wideHeight;

  static double heightFor({
    required bool isWideLayout,
    double mobileHeight = defaultMobileHeight,
    double wideHeight = defaultWideHeight,
  }) {
    return isWideLayout ? wideHeight : mobileHeight;
  }

  static MoviHeroOverlaySpec overlaySpecFor({required bool isWideLayout}) {
    return MoviHeroOverlaySpec.detail(isWideLayout: isWideLayout);
  }

  @override
  Widget build(BuildContext context) {
    final heroHeight = heightFor(
      isWideLayout: isWideLayout,
      mobileHeight: mobileHeight,
      wideHeight: wideHeight,
    );

    return SizedBox(
      height: heroHeight,
      width: double.infinity,
      child: MoviHeroScene(
        background: background,
        imageHeight: heroHeight,
        overlaySpec: overlaySpec ?? overlaySpecFor(isWideLayout: isWideLayout),
        children: children,
      ),
    );
  }
}

class MoviDetailHeroTopBar extends StatelessWidget {
  const MoviDetailHeroTopBar({
    super.key,
    required this.isWideLayout,
    required this.horizontalPadding,
    required this.leading,
    this.trailing,
  });

  final bool isWideLayout;
  final double horizontalPadding;
  final Widget leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: isWideLayout ? 12 : 8,
      left: horizontalPadding,
      right: horizontalPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [leading, if (trailing != null) trailing!],
      ),
    );
  }
}

class MoviDetailHeroDesktopOverlay extends StatelessWidget {
  const MoviDetailHeroDesktopOverlay({
    super.key,
    required this.child,
    this.alignment = Alignment.centerLeft,
    this.maxWidth = 560,
  });

  final Widget child;
  final Alignment alignment;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: 50,
          end: 50,
          top: 48,
          bottom: 32,
        ),
        child: Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        ),
      ),
    );
  }
}

class MoviDetailHeroActionButton extends StatelessWidget {
  const MoviDetailHeroActionButton({
    super.key,
    required this.iconAsset,
    required this.semanticLabel,
    required this.onPressed,
    required this.isWideLayout,
    this.focusNode,
    this.iconWidth = 35,
    this.iconHeight = 35,
    this.padding,
  });

  final String iconAsset;
  final String semanticLabel;
  final VoidCallback onPressed;
  final bool isWideLayout;
  final FocusNode? focusNode;
  final double iconWidth;
  final double iconHeight;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final hitPadding =
        padding ??
        EdgeInsets.symmetric(horizontal: isWideLayout ? 12 : 0, vertical: 8);

    return MoviFocusableAction(
      focusNode: focusNode,
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      builder: (context, state) {
        return MoviFocusFrame(
          scale: state.focused ? 1.04 : 1,
          padding: hitPadding,
          borderRadius: BorderRadius.circular(999),
          backgroundColor: state.focused
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.transparent,
          child: SizedBox(
            width: iconWidth,
            height: iconHeight,
            child: MoviAssetIcon(iconAsset, color: Colors.white),
          ),
        );
      },
    );
  }
}
