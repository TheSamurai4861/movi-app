import 'package:flutter/material.dart';

class LaunchRecoveryBanner extends StatelessWidget {
  const LaunchRecoveryBanner({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
            const SizedBox(width: 12),
            TextButton(onPressed: onRetry, child: const Text('Reessayer')),
          ],
        ),
      ),
    );
  }
}
