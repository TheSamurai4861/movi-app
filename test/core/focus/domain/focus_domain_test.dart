import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/directional_edge.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/domain/focus_region_exit_map.dart';
import 'package:movi/src/core/focus/domain/focus_restore_strategy.dart';

void main() {
  group('FocusRegionExitMap', () {
    test('resolves a target region for a directional edge', () {
      final exitMap = FocusRegionExitMap({
        DirectionalEdge.left: AppFocusRegionId.shellSidebar,
        DirectionalEdge.back: AppFocusRegionId.homePrimary,
      });

      expect(
        exitMap.targetFor(DirectionalEdge.left),
        AppFocusRegionId.shellSidebar,
      );
      expect(
        exitMap.targetFor(DirectionalEdge.back),
        AppFocusRegionId.homePrimary,
      );
      expect(exitMap.contains(DirectionalEdge.left), isTrue);
    });

    test('empty map does not resolve any directional edge', () {
      const exitMap = FocusRegionExitMap.empty();

      expect(exitMap.targetFor(DirectionalEdge.left), isNull);
      expect(exitMap.contains(DirectionalEdge.left), isFalse);
    });

    test('targets cannot be modified after creation', () {
      final exitMap = FocusRegionExitMap({
        DirectionalEdge.left: AppFocusRegionId.shellSidebar,
      });

      expect(
        () => exitMap.targets[DirectionalEdge.right] =
            AppFocusRegionId.searchInput,
        throwsUnsupportedError,
      );
    });
  });

  group('FocusRegionBinding', () {
    test('resolves the primary entry node lazily', () {
      final primaryNode = FocusNode(debugLabel: 'primary');
      addTearDown(primaryNode.dispose);

      final binding = FocusRegionBinding(
        resolvePrimaryEntryNode: () => primaryNode,
      );

      expect(binding.resolvePrimaryEntryNode(), same(primaryNode));
    });

    test('allows an absent fallback resolver', () {
      final primaryNode = FocusNode(debugLabel: 'primary');
      addTearDown(primaryNode.dispose);

      final binding = FocusRegionBinding(
        resolvePrimaryEntryNode: () => primaryNode,
      );

      expect(binding.resolveFallbackEntryNode, isNull);
    });

    test('uses restoreLastFocused as the default restore strategy', () {
      final primaryNode = FocusNode(debugLabel: 'primary');
      addTearDown(primaryNode.dispose);

      final binding = FocusRegionBinding(
        resolvePrimaryEntryNode: () => primaryNode,
      );

      expect(binding.restoreStrategy, FocusRestoreStrategy.restoreLastFocused);
    });
  });
}
