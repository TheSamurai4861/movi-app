import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:movi/src/core/focus/movi_overlay_focus_scope.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';

class MoviTvActionMenuAction {
  const MoviTvActionMenuAction({
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool destructive;
}

class MoviTvActionMenuDialog extends StatefulWidget {
  const MoviTvActionMenuDialog({
    super.key,
    this.title,
    required this.actions,
    required this.cancelLabel,
    this.triggerFocusNode,
  });

  final String? title;
  final List<MoviTvActionMenuAction> actions;
  final String cancelLabel;
  final FocusNode? triggerFocusNode;

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
          constraints: const BoxConstraints(maxWidth: 520),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                  if (widget.title != null && widget.title!.trim().isNotEmpty) ...[
                    Text(
                      widget.title!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  for (var i = 0; i < widget.actions.length; i++) ...[
                    _MoviTvActionMenuButton(
                      label: widget.actions[i].label,
                      destructive: widget.actions[i].destructive,
                      focusNode: _actionFocusNodes[i],
                      previousFocusNode: i > 0 ? _actionFocusNodes[i - 1] : null,
                      nextFocusNode: i == widget.actions.length - 1
                          ? _cancelFocusNode
                          : _actionFocusNodes[i + 1],
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.actions[i].onPressed();
                      },
                    ),
                    if (i != widget.actions.length - 1) const SizedBox(height: 12),
                  ],
                  if (widget.actions.isNotEmpty) const SizedBox(height: 18),
                  _MoviTvActionMenuButton(
                    label: widget.cancelLabel,
                    focusNode: _cancelFocusNode,
                    previousFocusNode: _actionFocusNodes.isNotEmpty
                        ? _actionFocusNodes.last
                        : null,
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
    ),
  );
}

class _MoviTvActionMenuButton extends StatelessWidget {
  const _MoviTvActionMenuButton({
    required this.label,
    required this.onPressed,
    required this.focusNode,
    this.previousFocusNode,
    this.nextFocusNode,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final FocusNode focusNode;
  final FocusNode? previousFocusNode;
  final FocusNode? nextFocusNode;
  final bool destructive;

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
        previousFocusNode != null &&
        previousFocusNode!.context != null &&
        previousFocusNode!.canRequestFocus) {
      previousFocusNode!.requestFocus();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
        nextFocusNode != null &&
        nextFocusNode!.context != null &&
        nextFocusNode!.canRequestFocus) {
      nextFocusNode!.requestFocus();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = destructive ? colorScheme.error : colorScheme.onSurface;

    return Focus(
      onKeyEvent: (_, event) => _handleKeyEvent(event),
      child: MoviFocusableAction(
        focusNode: focusNode,
        onPressed: onPressed,
        semanticLabel: label,
        builder: (context, state) {
          return MoviFocusFrame(
            scale: state.focused ? 1.02 : 1,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            borderRadius: BorderRadius.circular(20),
            backgroundColor: state.focused
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.04),
            borderColor: state.focused
                ? Colors.white
                : Colors.white.withValues(alpha: 0.06),
            borderWidth: 2,
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
          );
        },
      ),
    );
  }
}
