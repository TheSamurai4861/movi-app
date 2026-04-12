import 'package:flutter/widgets.dart';
import 'package:movi/src/core/focus/application/focus_orchestrator.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/directional_edge.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/domain/focus_region_exit_map.dart';
import 'package:movi/src/core/focus/domain/focus_restore_strategy.dart';
import 'package:movi/src/core/focus/infrastructure/focus_debug_logger.dart';
import 'package:movi/src/core/focus/infrastructure/focus_registry.dart';

class DefaultFocusOrchestrator implements FocusOrchestrator {
  DefaultFocusOrchestrator({
    FocusRegistry? registry,
    this.debugLogger = const FocusDebugLogger(),
  }) : _registry = registry ?? FocusRegistry();

  final FocusRegistry _registry;
  final FocusDebugLogger debugLogger;
  final Map<AppFocusRegionId, FocusNode> _lastFocusedNodes =
      <AppFocusRegionId, FocusNode>{};

  AppFocusRegionId? _activeRegionId;

  @override
  AppFocusRegionId? get activeRegionId => _activeRegionId;

  @override
  void registerRegion(
    AppFocusRegionId id,
    FocusRegionBinding binding, {
    FocusRegionExitMap exitMap = const FocusRegionExitMap.empty(),
  }) {
    _registry.register(id, binding, exitMap: exitMap);
    debugLogger.log('Registered focus region: $id');
  }

  @override
  void unregisterRegion(AppFocusRegionId id) {
    _registry.unregister(id);
    _lastFocusedNodes.remove(id);
    if (_activeRegionId == id) {
      _activeRegionId = null;
    }
    debugLogger.log('Unregistered focus region: $id');
  }

  @override
  void rememberFocusedNode(AppFocusRegionId id, FocusNode node) {
    if (!_isValidFocusNode(node)) {
      debugLogger.log('Ignored invalid focused node for region: $id');
      return;
    }
    _lastFocusedNodes[id] = node;
    debugLogger.log('Remembered focused node for region: $id');
  }

  @override
  bool enterRegion(AppFocusRegionId id, {bool restoreLastFocused = true}) {
    final registration = _registry.registrationFor(id);
    if (registration == null) {
      debugLogger.log('Cannot enter unregistered focus region: $id');
      return false;
    }

    final binding = registration.binding;
    final shouldRestoreLastFocused =
        restoreLastFocused &&
        binding.restoreStrategy == FocusRestoreStrategy.restoreLastFocused;

    if (shouldRestoreLastFocused &&
        _requestFocusIfValid(id, _lastFocusedNodes[id])) {
      debugLogger.log('Entered focus region from remembered node: $id');
      return true;
    }

    if (_requestFocusIfValid(id, binding.resolvePrimaryEntryNode())) {
      debugLogger.log('Entered focus region from primary node: $id');
      return true;
    }

    final fallbackNode = binding.resolveFallbackEntryNode?.call();
    if (_requestFocusIfValid(id, fallbackNode)) {
      debugLogger.log('Entered focus region from fallback node: $id');
      return true;
    }

    debugLogger.log('Failed to enter focus region: $id');
    return false;
  }

  @override
  bool resolveExit(AppFocusRegionId fromRegionId, DirectionalEdge edge) {
    final registration = _registry.registrationFor(fromRegionId);
    final targetRegionId = registration?.exitMap.targetFor(edge);
    if (targetRegionId == null) {
      debugLogger.log('No focus exit target for $fromRegionId on $edge');
      return false;
    }

    final handled = enterRegion(targetRegionId);
    debugLogger.log(
      handled
          ? 'Resolved focus exit from $fromRegionId to $targetRegionId'
          : 'Failed focus exit from $fromRegionId to $targetRegionId',
    );
    return handled;
  }

  @override
  bool isRegionRegistered(AppFocusRegionId id) {
    return _registry.contains(id);
  }

  bool _requestFocusIfValid(AppFocusRegionId id, FocusNode? node) {
    if (!_isValidFocusNode(node)) {
      if (identical(_lastFocusedNodes[id], node)) {
        _lastFocusedNodes.remove(id);
      }
      return false;
    }

    node!.requestFocus();
    _activeRegionId = id;
    _lastFocusedNodes[id] = node;
    return true;
  }

  bool _isValidFocusNode(FocusNode? node) {
    return node != null && node.context != null && node.canRequestFocus;
  }
}
