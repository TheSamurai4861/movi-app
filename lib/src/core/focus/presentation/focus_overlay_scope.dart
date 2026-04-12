import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/focus/application/focus_orchestrator.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/domain/focus_restore_strategy.dart';
import 'package:movi/src/core/focus/presentation/focus_orchestrator_provider.dart';
import 'package:movi/src/core/focus/presentation/focus_region_scope.dart';

class FocusOverlayScope extends ConsumerStatefulWidget {
  const FocusOverlayScope({
    super.key,
    required this.child,
    required this.initialFocusNode,
    this.fallbackFocusNode,
    this.triggerFocusNode,
    this.originRegionId,
    this.overlayRegionId = AppFocusRegionId.dialogPrimary,
    this.fallbackRegionId = AppFocusRegionId.shellSidebar,
    this.debugLabel,
  });

  final Widget child;
  final FocusNode initialFocusNode;
  final FocusNode? fallbackFocusNode;
  final FocusNode? triggerFocusNode;
  final AppFocusRegionId? originRegionId;
  final AppFocusRegionId overlayRegionId;
  final AppFocusRegionId? fallbackRegionId;
  final String? debugLabel;

  @override
  ConsumerState<FocusOverlayScope> createState() => _FocusOverlayScopeState();
}

class _FocusOverlayScopeState extends ConsumerState<FocusOverlayScope> {
  late final FocusScopeNode _focusScopeNode = FocusScopeNode(
    debugLabel: widget.debugLabel ?? 'FocusOverlayScope',
  );

  late final FocusOrchestrator _focusOrchestrator;
  late final AppFocusRegionId? _capturedOriginRegionId;

  @override
  void initState() {
    super.initState();
    _focusOrchestrator = ref.read(focusOrchestratorProvider);
    _capturedOriginRegionId =
        widget.originRegionId ?? _focusOrchestrator.activeRegionId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusOrchestrator.enterRegion(
        widget.overlayRegionId,
        restoreLastFocused: false,
      );
    });
  }

  @override
  void dispose() {
    final focusOrchestrator = _focusOrchestrator;
    final triggerFocusNode = widget.triggerFocusNode;
    final originRegionId = _capturedOriginRegionId;
    final fallbackFocusNode = widget.fallbackFocusNode;
    final fallbackRegionId = widget.fallbackRegionId;
    final overlayRegionId = widget.overlayRegionId;
    final focusScopeNode = _focusScopeNode;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentPrimaryFocus = FocusManager.instance.primaryFocus;
      if (currentPrimaryFocus != null &&
          !_isNodeInScope(currentPrimaryFocus, focusScopeNode)) {
        return;
      }
      if (_requestFocusIfValid(triggerFocusNode)) {
        return;
      }
      if (originRegionId != null &&
          originRegionId != overlayRegionId &&
          focusOrchestrator.enterRegion(originRegionId)) {
        return;
      }
      if (_requestFocusIfValid(fallbackFocusNode)) {
        return;
      }
      if (fallbackRegionId != null && fallbackRegionId != overlayRegionId) {
        focusOrchestrator.enterRegion(
          fallbackRegionId,
          restoreLastFocused: false,
        );
      }
    });

    _focusScopeNode.dispose();
    super.dispose();
  }

  static bool _requestFocusIfValid(FocusNode? node) {
    if (node == null || node.context == null || !node.canRequestFocus) {
      return false;
    }
    node.requestFocus();
    return true;
  }

  static bool _isNodeInScope(FocusNode node, FocusScopeNode scope) {
    FocusNode? cursor = node;
    while (cursor != null) {
      if (identical(cursor, scope)) {
        return true;
      }
      cursor = cursor.parent;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _focusScopeNode,
      autofocus: true,
      child: FocusRegionScope(
        regionId: widget.overlayRegionId,
        binding: FocusRegionBinding(
          resolvePrimaryEntryNode: () => widget.initialFocusNode,
          resolveFallbackEntryNode: () => widget.fallbackFocusNode,
          restoreStrategy: FocusRestoreStrategy.primaryOnly,
        ),
        debugLabel: widget.debugLabel,
        child: widget.child,
      ),
    );
  }
}
