import 'package:flutter/material.dart';

class SettingsPageWidth {
  SettingsPageWidth._();

  static const double maxWidth = 800;
}

class SettingsWidthConstraint extends StatelessWidget {
  const SettingsWidthConstraint({
    super.key,
    required this.child,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > SettingsPageWidth.maxWidth
            ? SettingsPageWidth.maxWidth
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
