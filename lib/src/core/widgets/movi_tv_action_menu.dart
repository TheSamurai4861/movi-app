import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:movi/src/core/focus/movi_overlay_focus_scope.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';

class MoviTvActionMenuAction {
  const MoviTvActionMenuAction({
    required this.label,
    required this.onPressed,
    this.destructive = false,
    this.leadingColor,
  });

  final String label;
  final VoidCallback onPressed;
  final bool destructive;
  final Color? leadingColor;
}

class MoviTvActionMenuDialog extends StatefulWidget {
  const MoviTvActionMenuDialog({
    super.key,
    this.title,
    required this.actions,
    required this.cancelLabel,
    this.triggerFocusNode,
    this.focusScale = 1.02,
    this.focusVerticalAlignment = 0.18,
  });

  final String? title;
  final List<MoviTvActionMenuAction> actions;
  final String cancelLabel;
  final FocusNode? triggerFocusNode;
  final double focusScale;
  final double focusVerticalAlignment;

  @override
  State<MoviTvActionMenuDialog> createState() => _MoviTvActionMenuDialogState();
}

class _MoviTvActionMenuDialogState extends State<MoviTvActionMenuDialog> {
  late final List<FocusNode> _actionFocusNodes = List<FocusNode>.generate(
    widget.actions.length,
    (index) => FocusNode(debugLabel: 'tv_action_menu_action_$index'),
  );
  late final FocusNode _cancelFocusNode = FocusNode(
    debugLabel: 'tv_action_menu_cancel',
  );

  @override
  void dispose() {
    for (final node in _actionFocusNodes) {
      node.dispose();
    }
    _cancelFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final maxDialogHeight = viewportHeight * 0.72;
    final maxActionsHeight = viewportHeight * 0.46;
    final initialFocusNode = _actionFocusNodes.isNotEmpty
        ? _actionFocusNodes.first
        : _cancelFocusNode;

    return MoviOverlayFocusScope(
      triggerFocusNode: widget.triggerFocusNode,
      initialFocusNode: initialFocusNode,
      fallbackFocusNode: _cancelFocusNode,
      debugLabel: 'MoviTvActionMenuDialog',
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 520,
            maxHeight: maxDialogHeight,
          ),
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
                  if (widget.title != null &&
                      widget.title!.trim().isNotEmpty) ...[
                    Text(
                      widget.title!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Flexible(
                    fit: FlexFit.loose,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxActionsHeight),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < widget.actions.length; i++) ...[
                              _MoviTvActionMenuButton(
                                label: widget.actions[i].label,
                                destructive: widget.actions[i].destructive,
                                leadingColor: widget.actions[i].leadingColor,
                                focusNode: _actionFocusNodes[i],
                                focusScale: widget.focusScale,
                                focusVerticalAlignment:
                                    widget.focusVerticalAlignment,
                                previousFocusNode: i > 0
                                    ? _actionFocusNodes[i - 1]
                                    : null,
                                nextFocusNode: i == widget.actions.length - 1
                                    ? _cancelFocusNode
                                    : _actionFocusNodes[i + 1],
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (!mounted) return;
                                    widget.actions[i].onPressed();
                                  });
                                },
                              ),
                              if (i != widget.actions.length - 1)
                                const SizedBox(height: 12),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (widget.actions.isNotEmpty) const SizedBox(height: 18),
                  _MoviTvActionMenuButton(
                    label: widget.cancelLabel,
                    focusNode: _cancelFocusNode,
                    focusScale: widget.focusScale,
                    focusVerticalAlignment: widget.focusVerticalAlignment,
                    previousFocusNode: _actionFocusNodes.isNotEmpty
                        ? _actionFocusNodes.last
                        : null,
                    isCancel: true,
                    onPressed: () => Navigator.of(context).pop(),
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

Future<void> showMoviTvActionMenu({
  required BuildContext context,
  String? title,
  required List<MoviTvActionMenuAction> actions,
  required String cancelLabel,
  double focusScale = 1.02,
  double focusVerticalAlignment = 0.18,
}) {
  final triggerFocusNode = FocusManager.instance.primaryFocus;
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => MoviTvActionMenuDialog(
      title: title,
      actions: actions,
      cancelLabel: cancelLabel,
      triggerFocusNode: triggerFocusNode,
      focusScale: focusScale,
      focusVerticalAlignment: focusVerticalAlignment,
    ),
  );
}

class _MoviTvActionMenuButton extends StatelessWidget {
  const _MoviTvActionMenuButton({
    required this.label,
    required this.onPressed,
    required this.focusNode,
    required this.focusScale,
    required this.focusVerticalAlignment,
    this.previousFocusNode,
    this.nextFocusNode,
    this.destructive = false,
    this.isCancel = false,
    this.leadingColor,
  });

  final String label;
  final VoidCallback onPressed;
  final FocusNode focusNode;
  final double focusScale;
  final double focusVerticalAlignment;
  final FocusNode? previousFocusNode;
  final FocusNode? nextFocusNode;
  final bool destructive;
  final bool isCancel;
  final Color? leadingColor;

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (previousFocusNode != null &&
          previousFocusNode!.context != null &&
          previousFocusNode!.canRequestFocus) {
        previousFocusNode!.requestFocus();
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (nextFocusNode != null &&
          nextFocusNode!.context != null &&
          nextFocusNode!.canRequestFocus) {
        nextFocusNode!.requestFocus();
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.arrowRight) {
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDangerAction = destructive || isCancel;
    final foreground = isDangerAction
        ? colorScheme.error
        : colorScheme.onSurface;
    final restingBorderColor = isDangerAction
        ? colorScheme.error.withValues(alpha: 0.8)
        : colorScheme.primary.withValues(alpha: 0.45);
    final focusedBorderColor = isDangerAction
        ? colorScheme.error
        : colorScheme.primary;

    return Focus(
      onKeyEvent: (_, event) => _handleKeyEvent(event),
      child: MoviEnsureVisibleOnFocus(
        verticalAlignment: focusVerticalAlignment,
        child: MoviFocusableAction(
          focusNode: focusNode,
          onPressed: onPressed,
          semanticLabel: label,
          builder: (context, state) {
            return MoviFocusFrame(
              scale: state.focused ? focusScale : 1,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              borderRadius: BorderRadius.circular(20),
              backgroundColor: state.focused
                  ? colorScheme.primary.withValues(alpha: 0.16)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
              borderColor: state.focused
                  ? focusedBorderColor
                  : restingBorderColor,
              borderWidth: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leadingColor != null) ...[
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: leadingColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w600,
                          ) ??
                          TextStyle(
                            color: foreground,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
