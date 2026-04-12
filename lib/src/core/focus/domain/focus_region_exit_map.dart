import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/directional_edge.dart';

class FocusRegionExitMap {
  FocusRegionExitMap([
    Map<DirectionalEdge, AppFocusRegionId> targets = const {},
  ]) : targets = Map<DirectionalEdge, AppFocusRegionId>.unmodifiable(targets);

  const FocusRegionExitMap.empty() : targets = const {};

  final Map<DirectionalEdge, AppFocusRegionId> targets;

  AppFocusRegionId? targetFor(DirectionalEdge edge) => targets[edge];

  bool contains(DirectionalEdge edge) => targets.containsKey(edge);
}
