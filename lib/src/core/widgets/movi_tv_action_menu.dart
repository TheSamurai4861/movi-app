import 'package:flutter/material.dart';

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

class MoviTvActionMenuDialog extends StatelessWidget {
  const MoviTvActionMenuDialog({
    super.key,
    this.title,
    required this.actions,
    required this.cancelLabel,
  });

  final String? title;
  final List<MoviTvActionMenuAction> actions;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
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
                if (title != null && title!.trim().isNotEmpty) ...[
                  Text(
                    title!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                for (var i = 0; i < actions.length; i++) ...[
                  _MoviTvActionMenuButton(
                    label: actions[i].label,
                    destructive: actions[i].destructive,
                    autofocus: i == 0,
                    onPressed: () {
                      Navigator.of(context).pop();
                      actions[i].onPressed();
                    },
                  ),
                  if (i != actions.length - 1) const SizedBox(height: 12),
                ],
                if (actions.isNotEmpty) const SizedBox(height: 18),
                _MoviTvActionMenuButton(
                  label: cancelLabel,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
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
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => MoviTvActionMenuDialog(
      title: title,
      actions: actions,
      cancelLabel: cancelLabel,
    ),
  );
}

class _MoviTvActionMenuButton extends StatelessWidget {
  const _MoviTvActionMenuButton({
    required this.label,
    required this.onPressed,
    this.autofocus = false,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool autofocus;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = destructive ? colorScheme.error : colorScheme.onSurface;

    return MoviFocusableAction(
      onPressed: onPressed,
      autofocus: autofocus,
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
    );
  }
}
