import 'package:flutter/material.dart';
import 'package:movi/src/core/focus/presentation/focus_overlay_scope.dart';

/// Focus boundary dedicated to dialogs, sheets and temporary overlays.
///
/// It requests an explicit entry node when mounted, traps focus inside the
/// overlay subtree and restores focus through the shared overlay policy when
/// the overlay is removed.
class MoviOverlayFocusScope extends StatelessWidget {
  const MoviOverlayFocusScope({
    super.key,
    required this.child,
    required this.initialFocusNode,
    this.fallbackFocusNode,
    this.triggerFocusNode,
    this.debugLabel,
  });

  final Widget child;
  final FocusNode initialFocusNode;
  final FocusNode? fallbackFocusNode;
  final FocusNode? triggerFocusNode;
  final String? debugLabel;

  @override
  Widget build(BuildContext context) {
    return FocusOverlayScope(
      initialFocusNode: initialFocusNode,
      fallbackFocusNode: fallbackFocusNode,
      triggerFocusNode: triggerFocusNode,
      debugLabel: debugLabel,
      child: child,
    );
  }
}
