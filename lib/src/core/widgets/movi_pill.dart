import 'dart:ui';

import 'package:flutter/material.dart';

/// Pill-shaped label with optional font size choices and blurred background.
class MoviPill extends StatelessWidget {
  const MoviPill(
    this.label, {
    super.key,
    this.large = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.trailingIcon,
    this.color,
  });

  /// Text to display inside the pill.
  final String label;

  /// If true, uses the larger text size (16px), otherwise 14px.
  final bool large;

  /// Custom padding for the pill content.
  final EdgeInsetsGeometry padding;

  /// Optional icon displayed to the right of the text.
  final Widget? trailingIcon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final textStyle = (large ? textTheme.labelLarge : textTheme.labelMedium)
        ?.copyWith(color: Colors.white, fontWeight: FontWeight.w500);

    final background = color ?? const Color(0x80292929);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                label,
                style:
                    textStyle ??
                    const TextStyle(fontSize: 14, color: Colors.white),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 4),
                SizedBox(
                  width: 18,
                  height: 18,
                  child: Center(
                    child: IconTheme.merge(
                      data: const IconThemeData(size: 18, color: Colors.white),
                      child: trailingIcon!,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
