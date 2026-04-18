import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movi/src/core/focus/presentation/focus_directional_navigation.dart';
import 'package:movi/src/core/focus/movi_focus_restore_policy.dart';

class MoviRouteFocusBoundary extends StatefulWidget {
  @Deprecated(
    'Use FocusRegionScope instead. This legacy boundary is kept only for temporary compatibility and must not be reintroduced in screens.',
  )
  const MoviRouteFocusBoundary({
    super.key,
    required this.child,
    required this.restorePolicy,
    this.onFocusedDescendant,
    this.onUnhandledLeft,
    this.onUnhandledBack,
    this.requestInitialFocusOnMount = false,
    this.debugLabel,
  });

  final Widget child;
  final MoviFocusRestorePolicy restorePolicy;
  final ValueChanged<FocusNode>? onFocusedDescendant;
  final bool Function()? onUnhandledLeft;
  final bool Function()? onUnhandledBack;
  final bool requestInitialFocusOnMount;
  final String? debugLabel;

  @override
  State<MoviRouteFocusBoundary> createState() => _MoviRouteFocusBoundaryState();
}

class _MoviRouteFocusBoundaryState extends State<MoviRouteFocusBoundary> {
  final GlobalKey _contentKey = GlobalKey();

  late final FocusNode _boundaryNode = FocusNode(
    debugLabel: widget.debugLabel ?? 'MoviRouteFocusBoundary',
    canRequestFocus: false,
    skipTraversal: true,
  );

  FocusNode? _lastFocusedDescendant;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_handlePrimaryFocusChanged);
    if (widget.requestInitialFocusOnMount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        requestEntryFocus();
      });
    }
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_handlePrimaryFocusChanged);
    _boundaryNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MoviRouteFocusBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    final lastFocused = _lastFocusedDescendant;
    if (!_isValidFocusNode(lastFocused)) {
      _lastFocusedDescendant = null;
    }
  }

  void requestEntryFocus() {
    final policy = widget.restorePolicy;
    if (policy.restoreFocusOnReturn &&
        _requestFocusIfValid(_lastFocusedDescendant)) {
      return;
    }
    if (_requestFocusIfValid(policy.initialFocusNode)) {
      return;
    }
    _requestFocusIfValid(policy.fallbackFocusNode);
  }

  void _handlePrimaryFocusChanged() {
    if (!mounted) return;
    final focusedNode = FocusManager.instance.primaryFocus;
    if (!_isFocusInsideBoundary(focusedNode)) {
      return;
    }
    if (identical(focusedNode, _boundaryNode)) {
      return;
    }
    if (identical(_lastFocusedDescendant, focusedNode)) {
      return;
    }
    _lastFocusedDescendant = focusedNode;
    if (focusedNode != null) {
      widget.onFocusedDescendant?.call(focusedNode);
    }
  }

  bool _isFocusInsideBoundary(FocusNode? node) {
    final boundaryObject = _contentKey.currentContext?.findRenderObject();
    final nodeObject = node?.context?.findRenderObject();
    if (boundaryObject == null || nodeObject == null) {
      return false;
    }

    RenderObject? current = nodeObject;
    while (current != null) {
      if (identical(current, boundaryObject)) {
        return true;
      }
      current = current.parent;
    }
    return false;
  }

  bool _requestFocusIfValid(FocusNode? node) {
    if (!_isValidFocusNode(node)) {
      return false;
    }
    node!.requestFocus();
    return true;
  }

  bool _isValidFocusNode(FocusNode? node) {
    return node != null && node.context != null && node.canRequestFocus;
  }

  KeyEventResult _handleBoundaryKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      final focusedNode = FocusManager.instance.primaryFocus;
      if (focusedNode != null &&
          focusedNode.focusInDirection(TraversalDirection.left)) {
        return KeyEventResult.handled;
      }
      final handled = widget.onUnhandledLeft?.call() ?? false;
      return handled ? KeyEventResult.handled : KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        FocusDirectionalNavigation.isEditableTextFocused()) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      final handled = widget.onUnhandledBack?.call() ?? false;
      return handled ? KeyEventResult.handled : KeyEventResult.ignored;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _boundaryNode,
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _handleBoundaryKeyEvent,
      child: KeyedSubtree(key: _contentKey, child: widget.child),
    );
  }
}
