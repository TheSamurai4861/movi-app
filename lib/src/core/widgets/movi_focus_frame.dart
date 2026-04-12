import 'package:flutter/material.dart';

class MoviInteractiveState {
  const MoviInteractiveState({
    required this.focused,
    required this.hovered,
    required this.pressed,
  });

  final bool focused;
  final bool hovered;
  final bool pressed;
}

typedef MoviFocusableBuilder =
    Widget Function(BuildContext context, MoviInteractiveState state);

class MoviFocusFrame extends StatelessWidget {
  const MoviFocusFrame({
    super.key,
    required this.child,
    this.scale = 1,
    this.padding = EdgeInsets.zero,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
    this.boxShadow,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 180),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final double scale;
  final EdgeInsetsGeometry padding;
  final BoxShape shape;
  final BorderRadiusGeometry? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;
  final AlignmentGeometry alignment;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;
    final effectiveBorderRadius = shape == BoxShape.circle ? null : radius;
    final hasDecoration =
        backgroundColor != null ||
        (borderColor != null && borderWidth > 0) ||
        (boxShadow != null && boxShadow!.isNotEmpty);

    return AnimatedScale(
      scale: scale,
      duration: duration,
      curve: curve,
      alignment: Alignment.center,
      child: AnimatedContainer(
        duration: duration,
        curve: curve,
        alignment: alignment,
        padding: padding,
        decoration: hasDecoration
            ? BoxDecoration(
                color: backgroundColor,
                shape: shape,
                borderRadius: effectiveBorderRadius,
                border: borderColor != null && borderWidth > 0
                    ? Border.all(color: borderColor!, width: borderWidth)
                    : null,
                boxShadow: boxShadow,
              )
            : null,
        child: child,
      ),
    );
  }
}
