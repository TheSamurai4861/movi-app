import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/features/settings/presentation/localization/movi_premium_localizer.dart';
import 'package:movi/src/features/settings/presentation/pages/movi_premium_page.dart';
import 'package:movi/src/features/settings/presentation/providers/movi_premium_providers.dart';

class LibraryPremiumBanner extends ConsumerWidget {
  const LibraryPremiumBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageState = ref.watch(moviPremiumPageStateProvider);
    if (pageState.hasActiveSubscription) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final localizer = MoviPremiumLocalizer.fromBuildContext(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizer.libraryBannerTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              localizer.libraryBannerBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 220,
              child: MoviPrimaryButton(
                label: localizer.libraryBannerAction,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MoviPremiumPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
