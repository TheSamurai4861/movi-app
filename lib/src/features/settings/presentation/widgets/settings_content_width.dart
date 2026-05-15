import 'package:flutter/material.dart';
import 'package:movi/src/core/responsive/presentation/extensions/tv_ui_scale_context.dart';

class SettingsContentWidth extends StatelessWidget {
  const SettingsContentWidth({
    super.key,
    required this.child,
    this.maxWidth = 800,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final uiScale = context.tvUiScale;
    final scaledMaxWidth = maxWidth * uiScale;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > scaledMaxWidth
            ? scaledMaxWidth
            : constraints.maxWidth;

        return Align(
          alignment: alignment,
          child: SizedBox(width: width, child: child),
        );
      },
    );
  }
}
