import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:movi/src/core/focus/movi_overlay_focus_scope.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/features/settings/presentation/localization/movi_premium_localizer.dart';
import 'package:movi/src/features/settings/presentation/pages/movi_premium_page.dart';

Future<void> showPremiumFeatureLockedSheet(
  BuildContext context, {
  FocusNode? triggerFocusNode,
}) {
  final localizer = MoviPremiumLocalizer.fromBuildContext(context);
  final effectiveTriggerFocusNode =
      triggerFocusNode ?? FocusManager.instance.primaryFocus;
  final size = MediaQuery.sizeOf(context);
  final screenType = ScreenTypeResolver.instance.resolve(
    size.width,
    size.height,
  );
  final isDesktopLike =
      screenType == ScreenType.desktop || screenType == ScreenType.tv;

  if (isDesktopLike) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _PremiumFeatureLockedDialog(
        localizer: localizer,
        parentContext: context,
        triggerFocusNode: effectiveTriggerFocusNode,
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return _PremiumFeatureLockedBottomSheet(
        localizer: localizer,
        parentContext: context,
        triggerFocusNode: effectiveTriggerFocusNode,
      );
    },
  );
}

class _PremiumFeatureLockedBottomSheet extends StatefulWidget {
  const _PremiumFeatureLockedBottomSheet({
    required this.localizer,
    required this.parentContext,
    this.triggerFocusNode,
  });

  final MoviPremiumLocalizer localizer;
  final BuildContext parentContext;
  final FocusNode? triggerFocusNode;

  @override
  State<_PremiumFeatureLockedBottomSheet> createState() =>
      _PremiumFeatureLockedBottomSheetState();
}

class _PremiumFeatureLockedBottomSheetState
    extends State<_PremiumFeatureLockedBottomSheet> {
  late final FocusNode _actionFocusNode = FocusNode(
    debugLabel: 'PremiumLockedBottomSheetAction',
  );
  late final FocusNode _dismissFocusNode = FocusNode(
    debugLabel: 'PremiumLockedBottomSheetDismiss',
  );

  @override
  void dispose() {
    _actionFocusNode.dispose();
    _dismissFocusNode.dispose();
    super.dispose();
  }

  void _openPremiumPage() {
    Navigator.of(context).pop();
    Navigator.of(
      widget.parentContext,
    ).push(MaterialPageRoute<void>(builder: (_) => const MoviPremiumPage()));
  }

  @override
  Widget build(BuildContext context) {
    return MoviOverlayFocusScope(
      triggerFocusNode: widget.triggerFocusNode,
      initialFocusNode: _actionFocusNode,
      fallbackFocusNode: _dismissFocusNode,
      debugLabel: 'PremiumFeatureLockedBottomSheet',
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.localizer.contextualUpsellTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                widget.localizer.contextualUpsellBody,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Focus(
                canRequestFocus: false,
                onKeyEvent: (_, event) {
                  if (event is! KeyDownEvent) {
                    return KeyEventResult.ignored;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    _dismissFocusNode.requestFocus();
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                      event.logicalKey == LogicalKeyboardKey.arrowRight) {
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: MoviPrimaryButton(
                  label: widget.localizer.contextualUpsellAction,
                  focusNode: _actionFocusNode,
                  onPressed: _openPremiumPage,
                ),
              ),
              const SizedBox(height: 12),
              Focus(
                canRequestFocus: false,
                onKeyEvent: (_, event) {
                  if (event is! KeyDownEvent) {
                    return KeyEventResult.ignored;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    _actionFocusNode.requestFocus();
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
                      event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                      event.logicalKey == LogicalKeyboardKey.arrowRight) {
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    focusNode: _dismissFocusNode,
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(widget.localizer.contextualUpsellDismiss),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumFeatureLockedDialog extends StatefulWidget {
  const _PremiumFeatureLockedDialog({
    required this.localizer,
    required this.parentContext,
    this.triggerFocusNode,
  });

  final MoviPremiumLocalizer localizer;
  final BuildContext parentContext;
  final FocusNode? triggerFocusNode;

  @override
  State<_PremiumFeatureLockedDialog> createState() =>
      _PremiumFeatureLockedDialogState();
}

class _PremiumFeatureLockedDialogState
    extends State<_PremiumFeatureLockedDialog> {
  late final FocusNode _actionFocusNode = FocusNode(
    debugLabel: 'PremiumLockedAction',
  );
  late final FocusNode _dismissFocusNode = FocusNode(
    debugLabel: 'PremiumLockedDismiss',
  );

  @override
  void dispose() {
    _actionFocusNode.dispose();
    _dismissFocusNode.dispose();
    super.dispose();
  }

  void _openPremiumPage() {
    Navigator.of(context).pop();
    Navigator.of(
      widget.parentContext,
    ).push(MaterialPageRoute<void>(builder: (_) => const MoviPremiumPage()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MoviOverlayFocusScope(
      triggerFocusNode: widget.triggerFocusNode,
      initialFocusNode: _actionFocusNode,
      fallbackFocusNode: _dismissFocusNode,
      debugLabel: 'PremiumFeatureLockedDialog',
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 32,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.localizer.contextualUpsellTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.localizer.contextualUpsellBody,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Focus(
                    canRequestFocus: false,
                    onKeyEvent: (_, event) {
                      if (event is! KeyDownEvent) {
                        return KeyEventResult.ignored;
                      }
                      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        _dismissFocusNode.requestFocus();
                        return KeyEventResult.handled;
                      }
                      if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                          event.logicalKey == LogicalKeyboardKey.arrowRight) {
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: MoviPrimaryButton(
                      label: widget.localizer.contextualUpsellAction,
                      focusNode: _actionFocusNode,
                      onPressed: _openPremiumPage,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Focus(
                    canRequestFocus: false,
                    onKeyEvent: (_, event) {
                      if (event is! KeyDownEvent) {
                        return KeyEventResult.ignored;
                      }
                      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                        _actionFocusNode.requestFocus();
                        return KeyEventResult.handled;
                      }
                      if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                          event.logicalKey == LogicalKeyboardKey.arrowRight ||
                          event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: ListenableBuilder(
                      listenable: _dismissFocusNode,
                      builder: (context, _) {
                        final isFocused = _dismissFocusNode.hasFocus;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isFocused
                                  ? colorScheme.error
                                  : colorScheme.error.withValues(alpha: 0.8),
                              width: 2,
                            ),
                            color: isFocused
                                ? colorScheme.error.withValues(alpha: 0.14)
                                : colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.2),
                          ),
                          child: OutlinedButton(
                            focusNode: _dismissFocusNode,
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.error,
                              side: BorderSide.none,
                              minimumSize: const Size.fromHeight(52),
                              alignment: Alignment.center,
                              textStyle: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              shape: const StadiumBorder(),
                              overlayColor: Colors.transparent,
                            ),
                            child: Text(
                              widget.localizer.contextualUpsellDismiss,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
