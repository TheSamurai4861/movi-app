import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/focus/application/focus_orchestrator.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/directional_edge.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/domain/focus_region_exit_map.dart';
import 'package:movi/src/core/focus/presentation/focus_directional_navigation.dart';
import 'package:movi/src/core/focus/presentation/focus_orchestrator_provider.dart';

class FocusRegionScope extends ConsumerStatefulWidget {
  const FocusRegionScope({
    super.key,
    required this.regionId,
    required this.binding,
    required this.child,
    this.exitMap = const FocusRegionExitMap.empty(),
    this.requestFocusOnMount = false,
    this.handleDirectionalExits = true,
    this.debugLabel,
  });

  final AppFocusRegionId regionId;
  final FocusRegionBinding binding;
  final FocusRegionExitMap exitMap;
  final bool requestFocusOnMount;
  final bool handleDirectionalExits;
  final String? debugLabel;
  final Widget child;

  @override
  ConsumerState<FocusRegionScope> createState() => _FocusRegionScopeState();
}

class _FocusRegionScopeState extends ConsumerState<FocusRegionScope> {
  final GlobalKey _contentKey = GlobalKey();
  late final FocusNode _scopeNode = FocusNode(
    debugLabel: widget.debugLabel ?? 'FocusRegionScope',
    canRequestFocus: false,
    skipTraversal: true,
  );

  late FocusOrchestrator _focusOrchestrator;

  @override
  void initState() {
    super.initState();
    _focusOrchestrator = ref.read(focusOrchestratorProvider);
    FocusManager.instance.addListener(_handlePrimaryFocusChanged);
    _registerRegion();
    if (widget.requestFocusOnMount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focusOrchestrator.enterRegion(widget.regionId);
      });
    }
  }

  @override
  void didUpdateWidget(covariant FocusRegionScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.regionId != widget.regionId) {
      _focusOrchestrator.unregisterRegion(oldWidget.regionId);
      _registerRegion();
      return;
    }
    if (!identical(oldWidget.binding, widget.binding) ||
        !identical(oldWidget.exitMap, widget.exitMap)) {
      _registerRegion();
    }
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_handlePrimaryFocusChanged);
    _focusOrchestrator.unregisterRegion(widget.regionId);
    _scopeNode.dispose();
    super.dispose();
  }

  void _registerRegion() {
    _focusOrchestrator.registerRegion(
      widget.regionId,
      widget.binding,
      exitMap: widget.exitMap,
    );
  }

  void _handlePrimaryFocusChanged() {
    if (!mounted) return;
    final focusedNode = FocusManager.instance.primaryFocus;
    if (!_isFocusInsideScope(focusedNode)) {
      return;
    }
    if (identical(focusedNode, _scopeNode)) {
      return;
    }
    if (!_isValidFocusNode(focusedNode)) {
      return;
    }
    _focusOrchestrator.rememberFocusedNode(widget.regionId, focusedNode!);
  }

  bool _isFocusInsideScope(FocusNode? node) {
    final scopeObject = _contentKey.currentContext?.findRenderObject();
    final nodeObject = node?.context?.findRenderObject();
    if (scopeObject == null || nodeObject == null) {
      return false;
    }

    RenderObject? current = nodeObject;
    while (current != null) {
      if (identical(current, scopeObject)) {
        return true;
      }
      current = current.parent;
    }
    return false;
  }

  bool _isValidFocusNode(FocusNode? node) {
    return node != null && node.context != null && node.canRequestFocus;
  }

  KeyEventResult _handleScopeKeyEvent(FocusNode node, KeyEvent event) {
    if (!widget.handleDirectionalExits || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final edge = _directionalEdgeForKey(event.logicalKey);
    if (edge == null) return KeyEventResult.ignored;
    return _resolveDirectionalEdge(edge);
  }

  DirectionalEdge? _directionalEdgeForKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowLeft) return DirectionalEdge.left;
    if (key == LogicalKeyboardKey.arrowRight) return DirectionalEdge.right;
    if (key == LogicalKeyboardKey.arrowUp) return DirectionalEdge.up;
    if (key == LogicalKeyboardKey.arrowDown) return DirectionalEdge.down;
    if (key == LogicalKeyboardKey.backspace &&
        FocusDirectionalNavigation.isEditableTextFocused()) {
      return null;
    }
    if (key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.backspace) {
      return DirectionalEdge.back;
    }
    return null;
  }

  KeyEventResult _resolveDirectionalEdge(DirectionalEdge edge) {
    if (edge != DirectionalEdge.back && _tryMoveFocusLocally(edge)) {
      return KeyEventResult.handled;
    }
    return _resolveExit(edge);
  }

  bool _tryMoveFocusLocally(DirectionalEdge edge) {
    final traversalDirection = _traversalDirectionFor(edge);
    if (traversalDirection == null) return false;
    final focusedNode = FocusManager.instance.primaryFocus;
    if (focusedNode == null) return false;
    return focusedNode.focusInDirection(traversalDirection);
  }

  TraversalDirection? _traversalDirectionFor(DirectionalEdge edge) {
    return switch (edge) {
      DirectionalEdge.left => TraversalDirection.left,
      DirectionalEdge.right => TraversalDirection.right,
      DirectionalEdge.up => TraversalDirection.up,
      DirectionalEdge.down => TraversalDirection.down,
      DirectionalEdge.back => null,
    };
  }

  KeyEventResult _resolveExit(DirectionalEdge edge) {
    final handled = _focusOrchestrator.resolveExit(widget.regionId, edge);
    return handled ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _scopeNode,
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _handleScopeKeyEvent,
      child: KeyedSubtree(key: _contentKey, child: widget.child),
    );
  }
}
