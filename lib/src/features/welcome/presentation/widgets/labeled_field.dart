import 'package:flutter/material.dart';
import 'package:movi/src/core/utils/app_spacing.dart';

class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}
