import 'package:flutter/material.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/utils/app_spacing.dart';

/// Widget affichant un message d'erreur sur la page d'accueil.
class HomeErrorBanner extends StatelessWidget {
  const HomeErrorBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.homeErrorSwipeToRetry,
                style:
                    (theme.textTheme.bodyMedium?.copyWith(color: Colors.red)) ??
                    theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
