import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/focus/application/default_focus_orchestrator.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/directional_edge.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/domain/focus_region_exit_map.dart';
import 'package:movi/src/core/focus/domain/focus_restore_strategy.dart';
import 'package:movi/src/core/focus/infrastructure/focus_debug_logger.dart';

void main() {
  testWidgets('enters a registered region through its primary node', (
    tester,
  ) async {
    final primaryNode = FocusNode(debugLabel: 'primary');
    addTearDown(primaryNode.dispose);
    await _pumpFocusNodes(tester, <FocusNode>[primaryNode]);

    final orchestrator = DefaultFocusOrchestrator()
      ..registerRegion(
        AppFocusRegionId.searchInput,
        FocusRegionBinding(resolvePrimaryEntryNode: () => primaryNode),
      );

    expect(orchestrator.enterRegion(AppFocusRegionId.searchInput), isTrue);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, same(primaryNode));
    expect(orchestrator.activeRegionId, AppFocusRegionId.searchInput);
  });

  testWidgets('uses fallback when the primary node is invalid', (tester) async {
    final primaryNode = FocusNode(debugLabel: 'primary');
    final fallbackNode = FocusNode(debugLabel: 'fallback');
    addTearDown(primaryNode.dispose);
    addTearDown(fallbackNode.dispose);
    await _pumpFocusNodes(tester, <FocusNode>[fallbackNode]);

    final orchestrator = DefaultFocusOrchestrator()
      ..registerRegion(
        AppFocusRegionId.searchInput,
        FocusRegionBinding(
          resolvePrimaryEntryNode: () => primaryNode,
          resolveFallbackEntryNode: () => fallbackNode,
        ),
      );

    expect(orchestrator.enterRegion(AppFocusRegionId.searchInput), isTrue);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, same(fallbackNode));
  });

  testWidgets('restores the remembered node before the primary node', (
    tester,
  ) async {
    final primaryNode = FocusNode(debugLabel: 'primary');
    final rememberedNode = FocusNode(debugLabel: 'remembered');
    addTearDown(primaryNode.dispose);
    addTearDown(rememberedNode.dispose);
    await _pumpFocusNodes(tester, <FocusNode>[primaryNode, rememberedNode]);

    final orchestrator = DefaultFocusOrchestrator()
      ..registerRegion(
        AppFocusRegionId.searchInput,
        FocusRegionBinding(resolvePrimaryEntryNode: () => primaryNode),
      )
      ..rememberFocusedNode(AppFocusRegionId.searchInput, rememberedNode);

    expect(orchestrator.enterRegion(AppFocusRegionId.searchInput), isTrue);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, same(rememberedNode));
  });

  testWidgets('primaryOnly ignores the remembered node', (tester) async {
    final primaryNode = FocusNode(debugLabel: 'primary');
    final rememberedNode = FocusNode(debugLabel: 'remembered');
    addTearDown(primaryNode.dispose);
    addTearDown(rememberedNode.dispose);
    await _pumpFocusNodes(tester, <FocusNode>[primaryNode, rememberedNode]);

    final orchestrator = DefaultFocusOrchestrator()
      ..registerRegion(
        AppFocusRegionId.searchInput,
        FocusRegionBinding(
          resolvePrimaryEntryNode: () => primaryNode,
          restoreStrategy: FocusRestoreStrategy.primaryOnly,
        ),
      )
      ..rememberFocusedNode(AppFocusRegionId.searchInput, rememberedNode);

    expect(orchestrator.enterRegion(AppFocusRegionId.searchInput), isTrue);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, same(primaryNode));
  });

  testWidgets('rememberFocusedNode ignores an invalid node', (tester) async {
    final primaryNode = FocusNode(debugLabel: 'primary');
    final initiallyInvalidNode = FocusNode(debugLabel: 'initially-invalid');
    addTearDown(primaryNode.dispose);
    addTearDown(initiallyInvalidNode.dispose);

    final orchestrator = DefaultFocusOrchestrator()
      ..rememberFocusedNode(AppFocusRegionId.searchInput, initiallyInvalidNode);

    await _pumpFocusNodes(tester, <FocusNode>[
      primaryNode,
      initiallyInvalidNode,
    ]);
    orchestrator.registerRegion(
      AppFocusRegionId.searchInput,
      FocusRegionBinding(resolvePrimaryEntryNode: () => primaryNode),
    );

    expect(orchestrator.enterRegion(AppFocusRegionId.searchInput), isTrue);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, same(primaryNode));
  });

  testWidgets('resolveExit enters the declared target region', (tester) async {
    final sourceNode = FocusNode(debugLabel: 'source');
    final targetNode = FocusNode(debugLabel: 'target');
    addTearDown(sourceNode.dispose);
    addTearDown(targetNode.dispose);
    await _pumpFocusNodes(tester, <FocusNode>[sourceNode, targetNode]);

    final orchestrator = DefaultFocusOrchestrator()
      ..registerRegion(
        AppFocusRegionId.searchInput,
        FocusRegionBinding(resolvePrimaryEntryNode: () => sourceNode),
        exitMap: FocusRegionExitMap({
          DirectionalEdge.left: AppFocusRegionId.shellSidebar,
        }),
      )
      ..registerRegion(
        AppFocusRegionId.shellSidebar,
        FocusRegionBinding(resolvePrimaryEntryNode: () => targetNode),
      );

    expect(
      orchestrator.resolveExit(
        AppFocusRegionId.searchInput,
        DirectionalEdge.left,
      ),
      isTrue,
    );
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, same(targetNode));
    expect(orchestrator.activeRegionId, AppFocusRegionId.shellSidebar);
  });

  test('resolveExit returns false when no target is declared', () {
    final orchestrator = DefaultFocusOrchestrator()
      ..registerRegion(
        AppFocusRegionId.searchInput,
        FocusRegionBinding(resolvePrimaryEntryNode: () => null),
      );

    expect(
      orchestrator.resolveExit(
        AppFocusRegionId.searchInput,
        DirectionalEdge.left,
      ),
      isFalse,
    );
  });

  test('enterRegion returns false for an unregistered region', () {
    final orchestrator = DefaultFocusOrchestrator();

    expect(orchestrator.enterRegion(AppFocusRegionId.searchInput), isFalse);
  });

  testWidgets('unregisterRegion removes registration and remembered node', (
    tester,
  ) async {
    final primaryNode = FocusNode(debugLabel: 'primary');
    final rememberedNode = FocusNode(debugLabel: 'remembered');
    addTearDown(primaryNode.dispose);
    addTearDown(rememberedNode.dispose);
    await _pumpFocusNodes(tester, <FocusNode>[primaryNode, rememberedNode]);

    final orchestrator = DefaultFocusOrchestrator()
      ..registerRegion(
        AppFocusRegionId.searchInput,
        FocusRegionBinding(resolvePrimaryEntryNode: () => primaryNode),
      )
      ..rememberFocusedNode(AppFocusRegionId.searchInput, rememberedNode)
      ..unregisterRegion(AppFocusRegionId.searchInput)
      ..registerRegion(
        AppFocusRegionId.searchInput,
        FocusRegionBinding(resolvePrimaryEntryNode: () => primaryNode),
      );

    expect(orchestrator.enterRegion(AppFocusRegionId.searchInput), isTrue);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, same(primaryNode));
  });

  test('debug logger is silent by default', () {
    final messages = <String>[];
    const logger = FocusDebugLogger();

    logger.log('hidden');

    expect(messages, isEmpty);
  });

  test('debug logger writes to sink when enabled', () {
    final messages = <String>[];
    final logger = FocusDebugLogger(enabled: true, sink: messages.add);

    logger.log('visible');

    expect(messages, <String>['visible']);
  });
}

Future<void> _pumpFocusNodes(WidgetTester tester, List<FocusNode> nodes) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Column(
          children: <Widget>[
            for (final node in nodes)
              Focus(
                focusNode: node,
                child: SizedBox(width: 1, height: 1, key: ValueKey(node)),
              ),
          ],
        ),
      ),
    ),
  );
}
