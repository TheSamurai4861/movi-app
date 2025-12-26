import 'package:flutter/material.dart';

/// Primary action button aligned with the app theme.
/// - Fills the maximum horizontal space allowed by its parent.
/// - Uses FilledButton to inherit `filledButtonTheme` from AppTheme.
/// - Pure widget: navigation logic must be provided via [onPressed].
class MoviPrimaryButton extends StatelessWidget {
  const MoviPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.assetIcon,
    this.leading,
    this.iconSize = 20,
    this.height = 48,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    this.buttonStyle,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;

  final bool loading;
  final String? assetIcon;
  final Widget? leading;
  final double iconSize;
  final double height;
  final EdgeInsetsGeometry padding;
  final ButtonStyle? buttonStyle;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final effectiveOnPressed = loading ? null : onPressed;

    Widget buildIcon() => Image.asset(
      assetIcon!,
      width: iconSize,
      height: iconSize,
      color: scheme.onPrimary,
      fit: BoxFit.contain,
    );

    Widget content;
    if (loading) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(scheme.onPrimary),
              backgroundColor: scheme.onPrimary.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onPrimary,
            ),
          ),
        ],
      );
    } else {
      final children = <Widget>[];
      if (assetIcon != null) {
        children.add(buildIcon());
        children.add(const SizedBox(width: 8));
      } else if (leading != null) {
        children.add(
          IconTheme.merge(
            data: IconThemeData(color: scheme.onPrimary, size: iconSize),
            child: leading!,
          ),
        );
        children.add(const SizedBox(width: 8));
      }
      children.add(
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onPrimary,
            ),
          ),
        ),
      );
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      );
    }

    final button = FilledButton(
      style: buttonStyle,
      onPressed: effectiveOnPressed,
      child: Padding(padding: padding, child: content),
    );

    final child = Semantics(
      button: true,
      enabled: effectiveOnPressed != null,
      label: label,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: expand
            ? SizedBox(width: double.infinity, child: button)
            : button,
      ),
    );
    return child;
  }
}
