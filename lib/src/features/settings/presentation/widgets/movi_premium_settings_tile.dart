import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/features/settings/presentation/localization/movi_premium_localizer.dart';
import 'package:movi/src/features/settings/presentation/pages/movi_premium_page.dart';
import 'package:movi/src/features/settings/presentation/providers/movi_premium_providers.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;

class MoviPremiumSettingsTile extends ConsumerWidget {
  const MoviPremiumSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageState = ref.watch(moviPremiumPageStateProvider);
    final localizer = MoviPremiumLocalizer.fromBuildContext(context);
    final accentColor = ref.watch(asp.currentAccentColorProvider);

    final subtitle = pageState.hasActiveSubscription
        ? localizer.entrySubtitleActive
        : localizer.entrySubtitle;

    return Focus(
      canRequestFocus: false,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const MoviPremiumPage()),
          );
        },
        focusColor: accentColor.withValues(alpha: 0.18),
        hoverColor: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.workspace_premium_outlined, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      localizer.entryTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              pageState.hasActiveSubscription
                  ? const Icon(Icons.verified, size: 20, color: Colors.white70)
                  : const Icon(Icons.chevron_right,
                      size: 20, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}
