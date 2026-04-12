import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;

class HomeHeroFilterBar extends ConsumerWidget {
  const HomeHeroFilterBar({super.key, this.moviesFocusNode});
  final FocusNode? moviesFocusNode;

  void _scrollToTop(BuildContext context) {
    final controller = PrimaryScrollController.maybeOf(context);
    if (controller == null || !controller.hasClients) {
      return;
    }
    if (controller.offset <= 0) {
      return;
    }
    controller.animateTo(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  KeyEventResult _handleSeriesKey(BuildContext context, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final isLtr = Directionality.of(context) == TextDirection.ltr;
    if (isLtr && event.logicalKey == LogicalKeyboardKey.arrowRight) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

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
            Focus(
              canRequestFocus: false,
              onFocusChange: (hasFocus) {
                if (hasFocus) {
                  _scrollToTop(context);
                }
              },
              child: _BlurPillButton(
                label: l10n.moviesTitle,
                isActive: mediaFilter == hp.HomeIptvMediaFilter.movies,
                activeColor: accentColor,
                focusNode: moviesFocusNode,
                onTap: () => ref
                    .read(hp.homeIptvMediaFilterProvider.notifier)
                    .toggle(hp.HomeIptvMediaFilter.movies),
              ),
            ),
            const SizedBox(width: 8),
            Focus(
              canRequestFocus: false,
              onFocusChange: (hasFocus) {
                if (hasFocus) {
                  _scrollToTop(context);
                }
              },
              onKeyEvent: (_, event) => _handleSeriesKey(context, event),
              child: _BlurPillButton(
                label: l10n.seriesTitle,
                isActive: mediaFilter == hp.HomeIptvMediaFilter.series,
                activeColor: accentColor,
                onTap: () => ref
                    .read(hp.homeIptvMediaFilterProvider.notifier)
                    .toggle(hp.HomeIptvMediaFilter.series),
              ),
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
    this.focusNode,
  });

  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color? activeColor;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final Color background = isActive
        ? (activeColor ?? Theme.of(context).colorScheme.primary)
        : const Color(0x80292929);
    final Color focusBackground = isActive
        ? (activeColor ?? Theme.of(context).colorScheme.primary)
        : const Color(0xAA303030);

    final borderColor = isActive
        ? (activeColor ?? Colors.white)
        : Colors.white30;

    return MoviFocusableAction(
      focusNode: focusNode,
      onPressed: onTap,
      semanticLabel: label,
      builder: (context, state) {
        final effectiveBackground = state.focused || state.hovered
            ? focusBackground
            : background;
        final effectiveBorder = state.focused ? Colors.white : borderColor;
        return Material(
          type: MaterialType.transparency,
          child: DefaultTextStyle.merge(
            style: const TextStyle(decoration: TextDecoration.none),
            child: MoviFocusFrame(
              scale: state.focused ? 1.05 : (state.hovered ? 1.02 : 1),
              borderRadius: BorderRadius.circular(999),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: effectiveBackground,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: effectiveBorder, width: 1.5),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
