import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;

class HomeHeroFilterBar extends ConsumerWidget {
  const HomeHeroFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final accentColor = ref.watch(asp.currentAccentColorProvider);
    final mediaFilter = ref.watch(hp.homeIptvMediaFilterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _BlurPillButton(
              label: l10n.moviesTitle,
              isActive: mediaFilter == hp.HomeIptvMediaFilter.movies,
              activeColor: accentColor,
              onTap: () => ref
                  .read(hp.homeIptvMediaFilterProvider.notifier)
                  .toggle(hp.HomeIptvMediaFilter.movies),
            ),
            const SizedBox(width: 8),
            _BlurPillButton(
              label: l10n.seriesTitle,
              isActive: mediaFilter == hp.HomeIptvMediaFilter.series,
              activeColor: accentColor,
              onTap: () => ref
                  .read(hp.homeIptvMediaFilterProvider.notifier)
                  .toggle(hp.HomeIptvMediaFilter.series),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlurPillButton extends StatelessWidget {
  const _BlurPillButton({
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.activeColor,
  });

  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final Color background = isActive
        ? (activeColor ?? Theme.of(context).colorScheme.primary)
        : const Color(0x80292929);

    final borderColor =
        isActive ? (activeColor ?? Colors.white) : Colors.white30;

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: borderColor,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
