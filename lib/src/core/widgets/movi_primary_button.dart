import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Primary action button aligned with the app theme.
/// - Fills the maximum horizontal space allowed by its parent.
/// - Uses FilledButton to inherit `filledButtonTheme` from AppTheme.
/// - Supports optional navigation (via GoRouter) and an optional asset icon.
class MoviPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  // Optional navigation support (used if onPressed is null)
  final String? routeName;
  final Map<String, String> pathParams;
  final Map<String, dynamic> queryParams;
  final Object? extra;
  final bool replace; // true => goNamed, false => pushNamed

  // Visuals
  final bool loading;
  final String? assetIcon; // e.g. AppAssets.iconSearch
  final Widget? leading; // alternative to assetIcon (e.g., Icon(Icons.play_arrow))
  final double iconSize;
  final double height;
  final EdgeInsetsGeometry padding;

  const MoviPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.routeName,
    this.pathParams = const {},
    this.queryParams = const {},
    this.extra,
    this.replace = false,
    this.loading = false,
    this.assetIcon,
    this.leading,
    this.iconSize = 20,
    this.height = 48,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    VoidCallback? effectiveOnPressed;
    if (!loading) {
      if (onPressed != null) {
        effectiveOnPressed = onPressed;
      } else if (routeName != null) {
        effectiveOnPressed = () {
          if (replace) {
            context.goNamed(
              routeName!,
              pathParameters: pathParams,
              queryParameters: queryParams,
              extra: extra,
            );
          } else {
            context.pushNamed(
              routeName!,
              pathParameters: pathParams,
              queryParameters: queryParams,
              extra: extra,
            );
          }
        };
      }
    }

    Widget buildIcon() => Image.asset(
          assetIcon!,
          width: iconSize,
          height: iconSize,
          // Tint to keep contrast on primary background (expects monochrome icon)
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
              backgroundColor: scheme.onPrimary.withOpacity(0.2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(color: scheme.onPrimary),
          ),
        ],
      );
    } else {
      final children = <Widget>[];
      if (assetIcon != null) {
        children.add(buildIcon());
        children.add(const SizedBox(width: 8));
      } else if (leading != null) {
        children.add(IconTheme.merge(
          data: IconThemeData(color: scheme.onPrimary, size: iconSize),
          child: leading!,
        ));
        children.add(const SizedBox(width: 8));
      }
      children.add(
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(color: scheme.onPrimary),
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
      onPressed: effectiveOnPressed,
      child: Padding(padding: padding, child: content),
    );

    // Take the maximum width allowed by parent constraints.
    return Semantics(
      button: true,
      enabled: effectiveOnPressed != null,
      label: label,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: SizedBox(
          width: double.infinity,
          child: button,
        ),
      ),
    );
  }
}
