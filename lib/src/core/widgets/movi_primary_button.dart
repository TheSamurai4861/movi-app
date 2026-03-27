import 'package:flutter/material.dart';

import 'package:movi/src/core/widgets/movi_asset_icon.dart';

/// Primary action button aligned with the app theme.
/// - Fills the maximum horizontal space allowed by its parent.
/// - Uses FilledButton to inherit `filledButtonTheme` from AppTheme.
/// - Pure widget: navigation logic must be provided via [onPressed].
class MoviPrimaryButton extends StatefulWidget {
  const MoviPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.focusNode,
    this.autofocus = false,
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
  final FocusNode? focusNode;
  final bool autofocus;
  final String? assetIcon;
  final Widget? leading;
  final double iconSize;
  final double height;
  final EdgeInsetsGeometry padding;
  final ButtonStyle? buttonStyle;
  final bool expand;

  @override
  State<MoviPrimaryButton> createState() => _MoviPrimaryButtonState();
}

class _MoviPrimaryButtonState extends State<MoviPrimaryButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final effectiveOnPressed = widget.loading ? null : widget.onPressed;

    Widget buildIcon() => MoviAssetIcon(
      widget.assetIcon!,
      size: widget.iconSize,
      color: scheme.onPrimary,
    );

    Widget content;
    if (widget.loading) {
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
            widget.label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onPrimary,
            ),
          ),
        ],
      );
    } else {
      final children = <Widget>[];
      if (widget.assetIcon != null) {
        children.add(buildIcon());
        children.add(const SizedBox(width: 8));
      } else if (widget.leading != null) {
        children.add(
          IconTheme.merge(
            data: IconThemeData(color: scheme.onPrimary, size: widget.iconSize),
            child: widget.leading!,
          ),
        );
        children.add(const SizedBox(width: 8));
      }
      children.add(
        Flexible(
          child: Text(
            widget.label,
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
      style: widget.buttonStyle,
      onPressed: effectiveOnPressed,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      child: Padding(padding: widget.padding, child: content),
    );

    final child = Focus(
      canRequestFocus: false,
      onFocusChange: (focused) {
        if (_focused == focused) return;
        setState(() => _focused = focused);
      },
      child: AnimatedScale(
        scale: _focused && effectiveOnPressed != null ? 1.03 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: _focused && effectiveOnPressed != null
                ? Border.all(
                    color: scheme.primary.withValues(alpha: 0.95),
                    width: 2,
                  )
                : null,
            boxShadow: _focused && effectiveOnPressed != null
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.18),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: button,
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: effectiveOnPressed != null,
      label: widget.label,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: widget.height),
        child: widget.expand
            ? SizedBox(width: double.infinity, child: child)
            : child,
      ),
    );
  }
}
