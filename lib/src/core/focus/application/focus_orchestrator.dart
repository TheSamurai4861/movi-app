import 'package:flutter/widgets.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/directional_edge.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/domain/focus_region_exit_map.dart';

abstract interface class FocusOrchestrator {
  AppFocusRegionId? get activeRegionId;

  void registerRegion(
    AppFocusRegionId id,
    FocusRegionBinding binding, {
    FocusRegionExitMap exitMap = const FocusRegionExitMap.empty(),
  });

  void unregisterRegion(AppFocusRegionId id);

  void rememberFocusedNode(AppFocusRegionId id, FocusNode node);

  bool enterRegion(AppFocusRegionId id, {bool restoreLastFocused = true});

  bool resolveExit(AppFocusRegionId fromRegionId, DirectionalEdge edge);

  bool isRegionRegistered(AppFocusRegionId id);
}
