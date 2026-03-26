import 'package:flutter/material.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > maxWidth
            ? maxWidth
            : constraints.maxWidth;

        return Align(
          alignment: alignment,
          child: SizedBox(
            width: width,
            child: child,
          ),
        );
      },
    );
  }
}
