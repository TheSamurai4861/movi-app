import 'package:flutter/material.dart';

import 'package:movi/src/core/widgets/movi_primary_button.dart';

class LaunchErrorPanel extends StatelessWidget {
  const LaunchErrorPanel({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    this.details,
    this.showDetails = false,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  final String? details;
  final bool showDetails;

  static const int _detailsMaxChars = 300;
  static const int _detailsMaxLines = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailsText = _truncateDetails(details);
    final showDetailsText = showDetails && detailsText != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (showDetailsText) ...[
              const SizedBox(height: 12),
              Text(
                detailsText,
                textAlign: TextAlign.center,
                maxLines: _detailsMaxLines,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 24),
            MoviPrimaryButton(
              label: retryLabel,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }

  String? _truncateDetails(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length <= _detailsMaxChars) return trimmed;
    return '${trimmed.substring(0, _detailsMaxChars)}...';
  }
}
