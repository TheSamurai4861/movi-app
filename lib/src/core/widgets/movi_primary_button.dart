import 'package:flutter/material.dart';

import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/core/responsive/presentation/extensions/tv_ui_scale_context.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';

/// Primary action button aligned with the app theme.
/// - Fills the maximum horizontal space allowed by its parent when [expand] is true.
/// - Height hugs label/icons with [padding] (16 px vertical by default).
/// - Uses FilledButton to inherit `filledButtonTheme` from AppTheme.
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
    this.iconSize = 28,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    this.iconGap = 16,
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
  final EdgeInsetsGeometry padding;
  final double iconGap;
  final ButtonStyle? buttonStyle;
  final bool expand;

  @override
  State<MoviPrimaryButton> createState() => _MoviPrimaryButtonState();
}

class _MoviPrimaryButtonState extends State<MoviPrimaryButton> {
  static const double _tvPaddingReductionFactor = 0.76;

  bool _focused = false;

  double _resolvePaddingScale(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTv =
        context.resolveScreenType(size.width, size.height) == ScreenType.tv;
    if (!isTv) return context.tvUiScale;
    return context.tvUiScale * _tvPaddingReductionFactor;
  }

  EdgeInsetsGeometry _scaleInsets(EdgeInsetsGeometry insets, double scale) {
    if (insets is EdgeInsets) {
      return EdgeInsets.fromLTRB(
        insets.left * scale,
        insets.top * scale,
        insets.right * scale,
        insets.bottom * scale,
      );
    }
    if (insets is EdgeInsetsDirectional) {
      return EdgeInsetsDirectional.fromSTEB(
        insets.start * scale,
        insets.top * scale,
        insets.end * scale,
        insets.bottom * scale,
      );
    }
    return insets;
  }

  @override
  Widget build(BuildContext context) {
    final paddingScale = _resolvePaddingScale(context);
    final scaledIconSize = widget.iconSize * paddingScale;
    final scaledPadding = _scaleInsets(widget.padding, paddingScale);
    final loaderSize = 18.0 * paddingScale;
    final contentGap = 12.0 * paddingScale;
    final iconGap = 8.0 * paddingScale;
    final focusBorderWidth = 2.0 * context.tvUiScale;
    final focusBlurRadius = 18.0 * context.tvUiScale;
    final focusSpreadRadius = 1.0 * context.tvUiScale;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final effectiveOnPressed = widget.loading ? null : widget.onPressed;
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      color: scheme.onPrimary,
    );

    Widget buildIcon() => MoviAssetIcon(
      widget.assetIcon!,
      size: scaledIconSize,
      color: scheme.onPrimary,
    );

    Widget buildLabel() => Text(
      widget.label,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: labelStyle,
    );

    final Widget content;
    if (widget.loading) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: loaderSize,
            height: loaderSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(scheme.onPrimary),
              backgroundColor: scheme.onPrimary.withValues(alpha: 0.2),
            ),
          ),
          SizedBox(width: contentGap),
          Flexible(child: buildLabel()),
        ],
      );
    } else if (widget.assetIcon != null || widget.leading != null) {
      final children = <Widget>[];
      if (widget.assetIcon != null) {
        children.add(buildIcon());
      } else {
        children.add(
          IconTheme.merge(
            data: IconThemeData(color: scheme.onPrimary, size: scaledIconSize),
            child: widget.leading!,
          ),
        );
      }
      children
        ..add(SizedBox(width: iconGap))
        ..add(Flexible(child: buildLabel()));
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: iconGap,
        children: children,
      );
    } else {
      content = buildLabel();
    }

    final button = FilledButton(
      style: ButtonStyle(
        padding: WidgetStateProperty.all(scaledPadding),
        minimumSize: WidgetStateProperty.all(Size.zero),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        alignment: Alignment.center,
      ).merge(widget.buttonStyle ?? theme.filledButtonTheme.style),
      onPressed: effectiveOnPressed,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      child: content,
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
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _focused && effectiveOnPressed != null
                  ? scheme.primary.withValues(alpha: 0.95)
                  : Colors.transparent,
              width: focusBorderWidth,
            ),
            boxShadow: _focused && effectiveOnPressed != null
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.18),
                      blurRadius: focusBlurRadius,
                      spreadRadius: focusSpreadRadius,
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
      child: widget.expand
          ? SizedBox(width: double.infinity, child: child)
          : child,
    );
  }
}
