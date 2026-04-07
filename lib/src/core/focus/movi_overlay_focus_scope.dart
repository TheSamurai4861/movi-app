import 'package:flutter/material.dart';
import 'package:movi/src/core/focus/movi_focus_restore_policy.dart';
import 'package:movi/src/core/focus/movi_route_focus_boundary.dart';

/// Focus boundary dedicated to dialogs, sheets and temporary overlays.
///
/// It requests an explicit entry node when mounted, traps focus inside the
/// overlay subtree and restores focus to the original trigger when the overlay
/// is removed.
class MoviOverlayFocusScope extends StatefulWidget {
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
  State<MoviOverlayFocusScope> createState() => _MoviOverlayFocusScopeState();
}

class _MoviOverlayFocusScopeState extends State<MoviOverlayFocusScope> {
  late final FocusScopeNode _focusScopeNode = FocusScopeNode(
    debugLabel: widget.debugLabel ?? 'MoviOverlayFocusScope',
  );

  @override
  void dispose() {
    final triggerFocusNode = widget.triggerFocusNode;
    final fallbackFocusNode = widget.fallbackFocusNode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_requestFocusIfValid(triggerFocusNode)) {
        return;
      }
      _requestFocusIfValid(fallbackFocusNode);
    });
    _focusScopeNode.dispose();
    super.dispose();
  }

  bool _requestFocusIfValid(FocusNode? node) {
    if (node == null || node.context == null || !node.canRequestFocus) {
      return false;
    }
    node.requestFocus();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _focusScopeNode,
      autofocus: true,
      child: MoviRouteFocusBoundary(
        restorePolicy: MoviFocusRestorePolicy(
          initialFocusNode: widget.initialFocusNode,
          fallbackFocusNode: widget.fallbackFocusNode,
          restoreFocusOnReturn: false,
        ),
        requestInitialFocusOnMount: true,
        debugLabel: widget.debugLabel,
        child: widget.child,
      ),
    );
  }
}
