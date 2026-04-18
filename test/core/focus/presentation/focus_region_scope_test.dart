import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/focus/application/default_focus_orchestrator.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/directional_edge.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/domain/focus_region_exit_map.dart';
import 'package:movi/src/core/focus/presentation/focus_orchestrator_provider.dart';
import 'package:movi/src/core/focus/presentation/focus_region_scope.dart';

void main() {
  Future<void> pumpRegionScope(
    WidgetTester tester, {
    required DefaultFocusOrchestrator orchestrator,
    required AppFocusRegionId regionId,
    required FocusRegionBinding binding,
    required Widget child,
    FocusRegionExitMap exitMap = const FocusRegionExitMap.empty(),
    bool requestFocusOnMount = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [focusOrchestratorProvider.overrideWithValue(orchestrator)],
        child: MaterialApp(
          home: Scaffold(
            body: FocusRegionScope(
              regionId: regionId,
              binding: binding,
              exitMap: exitMap,
              requestFocusOnMount: requestFocusOnMount,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('registers a region when mounted', (tester) async {
    final orchestrator = DefaultFocusOrchestrator();
    final primaryNode = FocusNode(debugLabel: 'primary');
    addTearDown(primaryNode.dispose);

    await pumpRegionScope(
      tester,
      orchestrator: orchestrator,
      regionId: AppFocusRegionId.searchInput,
      binding: FocusRegionBinding(resolvePrimaryEntryNode: () => primaryNode),
      child: Focus(focusNode: primaryNode, child: const SizedBox()),
    );

    expect(orchestrator.isRegionRegistered(AppFocusRegionId.searchInput), true);
  });

  testWidgets('unregisters the region when disposed', (tester) async {
    final orchestrator = DefaultFocusOrchestrator();
    final primaryNode = FocusNode(debugLabel: 'primary');
    addTearDown(primaryNode.dispose);

    await pumpRegionScope(
      tester,
      orchestrator: orchestrator,
      regionId: AppFocusRegionId.searchInput,
      binding: FocusRegionBinding(resolvePrimaryEntryNode: () => primaryNode),
      child: Focus(focusNode: primaryNode, child: const SizedBox()),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [focusOrchestratorProvider.overrideWithValue(orchestrator)],
        child: const MaterialApp(home: SizedBox()),
      ),
    );

    expect(
      orchestrator.isRegionRegistered(AppFocusRegionId.searchInput),
      false,
    );
  });

  testWidgets('requestFocusOnMount focuses the primary node', (tester) async {
    final orchestrator = DefaultFocusOrchestrator();
    final primaryNode = FocusNode(debugLabel: 'primary');
    addTearDown(primaryNode.dispose);

    await pumpRegionScope(
      tester,
      orchestrator: orchestrator,
      regionId: AppFocusRegionId.searchInput,
      binding: FocusRegionBinding(resolvePrimaryEntryNode: () => primaryNode),
      requestFocusOnMount: true,
      child: Focus(focusNode: primaryNode, child: const SizedBox()),
    );
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, same(primaryNode));
  });

  testWidgets('remembers the last focused descendant for restoration', (
    tester,
  ) async {
    final orchestrator = DefaultFocusOrchestrator();
    final primaryNode = FocusNode(debugLabel: 'primary');
    final descendantNode = FocusNode(debugLabel: 'descendant');
    addTearDown(primaryNode.dispose);
    addTearDown(descendantNode.dispose);

    await pumpRegionScope(
      tester,
      orchestrator: orchestrator,
      regionId: AppFocusRegionId.searchInput,
      binding: FocusRegionBinding(resolvePrimaryEntryNode: () => primaryNode),
      child: Column(
        children: [
          Focus(focusNode: primaryNode, child: const SizedBox()),
          Focus(focusNode: descendantNode, child: const SizedBox()),
        ],
      ),
    );
    descendantNode.requestFocus();
    await tester.pump();

    expect(orchestrator.enterRegion(AppFocusRegionId.searchInput), true);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, same(descendantNode));
  });

  testWidgets('delegates back exits through the exit map', (tester) async {
    final orchestrator = DefaultFocusOrchestrator();
    final sourceNode = FocusNode(debugLabel: 'source');
    final targetNode = FocusNode(debugLabel: 'target');
    addTearDown(sourceNode.dispose);
    addTearDown(targetNode.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [focusOrchestratorProvider.overrideWithValue(orchestrator)],
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                FocusRegionScope(
                  regionId: AppFocusRegionId.searchInput,
                  binding: FocusRegionBinding(
                    resolvePrimaryEntryNode: () => sourceNode,
                  ),
                  exitMap: FocusRegionExitMap({
                    DirectionalEdge.back: AppFocusRegionId.shellSidebar,
                  }),
                  child: Focus(focusNode: sourceNode, child: const SizedBox()),
                ),
                FocusRegionScope(
                  regionId: AppFocusRegionId.shellSidebar,
                  binding: FocusRegionBinding(
                    resolvePrimaryEntryNode: () => targetNode,
                  ),
                  child: Focus(focusNode: targetNode, child: const SizedBox()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    sourceNode.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, same(targetNode));
  });

  testWidgets('ignores exits without a declared target', (tester) async {
    final orchestrator = DefaultFocusOrchestrator();
    final sourceNode = FocusNode(debugLabel: 'source');
    addTearDown(sourceNode.dispose);

    await pumpRegionScope(
      tester,
      orchestrator: orchestrator,
      regionId: AppFocusRegionId.searchInput,
      binding: FocusRegionBinding(resolvePrimaryEntryNode: () => sourceNode),
      child: Focus(focusNode: sourceNode, child: const SizedBox()),
    );
    sourceNode.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, same(sourceNode));
  });

  testWidgets(
    'delegates right exits through the exit map when local move fails',
    (tester) async {
      final orchestrator = DefaultFocusOrchestrator();
      final sourceNode = FocusNode(debugLabel: 'source');
      final targetNode = FocusNode(debugLabel: 'target');
      addTearDown(sourceNode.dispose);
      addTearDown(targetNode.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            focusOrchestratorProvider.overrideWithValue(orchestrator),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  FocusRegionScope(
                    regionId: AppFocusRegionId.searchInput,
                    binding: FocusRegionBinding(
                      resolvePrimaryEntryNode: () => sourceNode,
                    ),
                    exitMap: FocusRegionExitMap({
                      DirectionalEdge.right: AppFocusRegionId.shellSidebar,
                    }),
                    child: Focus(
                      focusNode: sourceNode,
                      child: const SizedBox(),
                    ),
                  ),
                  FocusRegionScope(
                    regionId: AppFocusRegionId.shellSidebar,
                    binding: FocusRegionBinding(
                      resolvePrimaryEntryNode: () => targetNode,
                    ),
                    child: Focus(
                      focusNode: targetNode,
                      child: const SizedBox(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      sourceNode.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, same(targetNode));
    },
  );

  testWidgets('delegates up exits through the exit map when local move fails', (
    tester,
  ) async {
    final orchestrator = DefaultFocusOrchestrator();
    final sourceNode = FocusNode(debugLabel: 'source');
    final targetNode = FocusNode(debugLabel: 'target');
    addTearDown(sourceNode.dispose);
    addTearDown(targetNode.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [focusOrchestratorProvider.overrideWithValue(orchestrator)],
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                FocusRegionScope(
                  regionId: AppFocusRegionId.searchInput,
                  binding: FocusRegionBinding(
                    resolvePrimaryEntryNode: () => sourceNode,
                  ),
                  exitMap: FocusRegionExitMap({
                    DirectionalEdge.up: AppFocusRegionId.shellSidebar,
                  }),
                  child: Focus(focusNode: sourceNode, child: const SizedBox()),
                ),
                FocusRegionScope(
                  regionId: AppFocusRegionId.shellSidebar,
                  binding: FocusRegionBinding(
                    resolvePrimaryEntryNode: () => targetNode,
                  ),
                  child: Focus(focusNode: targetNode, child: const SizedBox()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    sourceNode.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, same(targetNode));
  });

  testWidgets(
    'delegates down exits through the exit map when local move fails',
    (tester) async {
      final orchestrator = DefaultFocusOrchestrator();
      final sourceNode = FocusNode(debugLabel: 'source');
      final targetNode = FocusNode(debugLabel: 'target');
      addTearDown(sourceNode.dispose);
      addTearDown(targetNode.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            focusOrchestratorProvider.overrideWithValue(orchestrator),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  FocusRegionScope(
                    regionId: AppFocusRegionId.searchInput,
                    binding: FocusRegionBinding(
                      resolvePrimaryEntryNode: () => sourceNode,
                    ),
                    exitMap: FocusRegionExitMap({
                      DirectionalEdge.down: AppFocusRegionId.shellSidebar,
                    }),
                    child: Focus(
                      focusNode: sourceNode,
                      child: const SizedBox(),
                    ),
                  ),
                  FocusRegionScope(
                    regionId: AppFocusRegionId.shellSidebar,
                    binding: FocusRegionBinding(
                      resolvePrimaryEntryNode: () => targetNode,
                    ),
                    child: Focus(
                      focusNode: targetNode,
                      child: const SizedBox(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      sourceNode.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, same(targetNode));
    },
  );

  testWidgets(
    'prefers local move over exit map when directional traversal succeeds',
    (tester) async {
      final orchestrator = DefaultFocusOrchestrator();
      final sourceNode = FocusNode(debugLabel: 'source');
      final localRightNode = FocusNode(debugLabel: 'localRight');
      final targetNode = FocusNode(debugLabel: 'target');
      addTearDown(sourceNode.dispose);
      addTearDown(localRightNode.dispose);
      addTearDown(targetNode.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            focusOrchestratorProvider.overrideWithValue(orchestrator),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  FocusRegionScope(
                    regionId: AppFocusRegionId.searchInput,
                    binding: FocusRegionBinding(
                      resolvePrimaryEntryNode: () => sourceNode,
                    ),
                    exitMap: FocusRegionExitMap({
                      DirectionalEdge.right: AppFocusRegionId.shellSidebar,
                    }),
                    child: Row(
                      children: [
                        Focus(
                          focusNode: sourceNode,
                          child: const SizedBox(width: 40, height: 40),
                        ),
                        const SizedBox(width: 12),
                        Focus(
                          focusNode: localRightNode,
                          child: const SizedBox(width: 40, height: 40),
                        ),
                      ],
                    ),
                  ),
                  FocusRegionScope(
                    regionId: AppFocusRegionId.shellSidebar,
                    binding: FocusRegionBinding(
                      resolvePrimaryEntryNode: () => targetNode,
                    ),
                    child: Focus(
                      focusNode: targetNode,
                      child: const SizedBox(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      sourceNode.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, same(localRightNode));
    },
  );

  testWidgets('directional exits are ignored when disabled', (tester) async {
    final orchestrator = DefaultFocusOrchestrator();
    final sourceNode = FocusNode(debugLabel: 'source');
    final targetNode = FocusNode(debugLabel: 'target');
    addTearDown(sourceNode.dispose);
    addTearDown(targetNode.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [focusOrchestratorProvider.overrideWithValue(orchestrator)],
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                FocusRegionScope(
                  regionId: AppFocusRegionId.searchInput,
                  binding: FocusRegionBinding(
                    resolvePrimaryEntryNode: () => sourceNode,
                  ),
                  exitMap: FocusRegionExitMap({
                    DirectionalEdge.right: AppFocusRegionId.shellSidebar,
                    DirectionalEdge.up: AppFocusRegionId.shellSidebar,
                    DirectionalEdge.down: AppFocusRegionId.shellSidebar,
                  }),
                  handleDirectionalExits: false,
                  child: Focus(focusNode: sourceNode, child: const SizedBox()),
                ),
                FocusRegionScope(
                  regionId: AppFocusRegionId.shellSidebar,
                  binding: FocusRegionBinding(
                    resolvePrimaryEntryNode: () => targetNode,
                  ),
                  child: Focus(focusNode: targetNode, child: const SizedBox()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    sourceNode.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, same(sourceNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, same(sourceNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, same(sourceNode));
  });

  testWidgets('back, escape and backspace resolve through exit map', (
    tester,
  ) async {
    final orchestrator = DefaultFocusOrchestrator();
    final sourceNode = FocusNode(debugLabel: 'source');
    final targetNode = FocusNode(debugLabel: 'target');
    addTearDown(sourceNode.dispose);
    addTearDown(targetNode.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [focusOrchestratorProvider.overrideWithValue(orchestrator)],
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                FocusRegionScope(
                  regionId: AppFocusRegionId.searchInput,
                  binding: FocusRegionBinding(
                    resolvePrimaryEntryNode: () => sourceNode,
                  ),
                  exitMap: FocusRegionExitMap({
                    DirectionalEdge.back: AppFocusRegionId.shellSidebar,
                  }),
                  child: Focus(focusNode: sourceNode, child: const SizedBox()),
                ),
                FocusRegionScope(
                  regionId: AppFocusRegionId.shellSidebar,
                  binding: FocusRegionBinding(
                    resolvePrimaryEntryNode: () => targetNode,
                  ),
                  child: Focus(focusNode: targetNode, child: const SizedBox()),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    sourceNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, same(targetNode));

    sourceNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, same(targetNode));
  });

  testWidgets(
    'backspace does not resolve exit map when an editable text is focused',
    (tester) async {
      final orchestrator = DefaultFocusOrchestrator();
      final sourceNode = FocusNode(debugLabel: 'source');
      final targetNode = FocusNode(debugLabel: 'target');
      final textFocusNode = FocusNode(debugLabel: 'searchField');
      final textController = TextEditingController(text: 'abc');
      addTearDown(sourceNode.dispose);
      addTearDown(targetNode.dispose);
      addTearDown(textFocusNode.dispose);
      addTearDown(textController.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            focusOrchestratorProvider.overrideWithValue(orchestrator),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  FocusRegionScope(
                    regionId: AppFocusRegionId.searchInput,
                    binding: FocusRegionBinding(
                      resolvePrimaryEntryNode: () => sourceNode,
                    ),
                    exitMap: FocusRegionExitMap({
                      DirectionalEdge.back: AppFocusRegionId.shellSidebar,
                    }),
                    child: Column(
                      children: [
                        Focus(
                          focusNode: sourceNode,
                          child: const SizedBox(height: 1, width: 1),
                        ),
                        TextField(
                          focusNode: textFocusNode,
                          controller: textController,
                        ),
                      ],
                    ),
                  ),
                  FocusRegionScope(
                    regionId: AppFocusRegionId.shellSidebar,
                    binding: FocusRegionBinding(
                      resolvePrimaryEntryNode: () => targetNode,
                    ),
                    child: Focus(
                      focusNode: targetNode,
                      child: const SizedBox(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      textFocusNode.requestFocus();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, same(textFocusNode));

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, same(textFocusNode));
      expect(targetNode.hasFocus, isFalse);
    },
  );
}
