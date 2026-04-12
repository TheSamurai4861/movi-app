import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/focus/application/default_focus_orchestrator.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/directional_edge.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/domain/focus_region_exit_map.dart';
import 'package:movi/src/features/shell/presentation/navigation/shell_destinations.dart';
import 'package:movi/src/features/shell/presentation/providers/shell_providers.dart';

void main() {
  Future<void> pumpFocusNodes(
    WidgetTester tester,
    List<FocusNode> nodes,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              for (final node in nodes)
                Focus(
                  focusNode: node,
                  child: const SizedBox(width: 20, height: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }

  ShellFocusCoordinator coordinatorFor(DefaultFocusOrchestrator orchestrator) {
    return ShellFocusCoordinator(focusOrchestrator: orchestrator);
  }

  AppFocusRegionId regionForTab(ShellTab tab) {
    return switch (tab) {
      ShellTab.home => AppFocusRegionId.homePrimary,
      ShellTab.search => AppFocusRegionId.searchInput,
      ShellTab.library => AppFocusRegionId.libraryPrimary,
      ShellTab.settings => AppFocusRegionId.settingsPrimary,
    };
  }

  void registerTabRegion(
    DefaultFocusOrchestrator orchestrator,
    ShellTab tab, {
    required FocusNode primaryNode,
    FocusNode? fallbackNode,
    FocusRegionExitMap exitMap = const FocusRegionExitMap.empty(),
  }) {
    orchestrator.registerRegion(
      regionForTab(tab),
      FocusRegionBinding(
        resolvePrimaryEntryNode: () => primaryNode,
        resolveFallbackEntryNode: () => fallbackNode,
      ),
      exitMap: exitMap,
    );
  }

  testWidgets('attachSidebar registers shellSidebar and focuses it', (
    tester,
  ) async {
    final orchestrator = DefaultFocusOrchestrator();
    final coordinator = coordinatorFor(orchestrator);
    final sidebarNode = FocusNode(debugLabel: 'sidebar');
    addTearDown(sidebarNode.dispose);
    await pumpFocusNodes(tester, [sidebarNode]);

    coordinator.attachSidebar(sidebarNode);

    expect(
      orchestrator.isRegionRegistered(AppFocusRegionId.shellSidebar),
      isTrue,
    );
    expect(coordinator.focusSidebar(), isTrue);
    await tester.pump();

    expect(sidebarNode.hasFocus, isTrue);
  });

  testWidgets('detachSidebar unregisters shellSidebar', (tester) async {
    final orchestrator = DefaultFocusOrchestrator();
    final coordinator = coordinatorFor(orchestrator);
    final sidebarNode = FocusNode(debugLabel: 'sidebar');
    addTearDown(sidebarNode.dispose);
    await pumpFocusNodes(tester, [sidebarNode]);

    coordinator.attachSidebar(sidebarNode);
    coordinator.detachSidebar(sidebarNode);

    expect(
      orchestrator.isRegionRegistered(AppFocusRegionId.shellSidebar),
      isFalse,
    );
    expect(coordinator.focusSidebar(), isFalse);
  });

  testWidgets('focusTabEntry restores the last focused descendant', (
    tester,
  ) async {
    final orchestrator = DefaultFocusOrchestrator();
    final coordinator = coordinatorFor(orchestrator);
    final primaryNode = FocusNode(debugLabel: 'primary');
    final rememberedNode = FocusNode(debugLabel: 'remembered');
    addTearDown(primaryNode.dispose);
    addTearDown(rememberedNode.dispose);
    await pumpFocusNodes(tester, [primaryNode, rememberedNode]);

    registerTabRegion(orchestrator, ShellTab.home, primaryNode: primaryNode);
    orchestrator.rememberFocusedNode(
      AppFocusRegionId.homePrimary,
      rememberedNode,
    );

    expect(coordinator.focusTabEntry(ShellTab.home), isTrue);
    await tester.pump();

    expect(rememberedNode.hasFocus, isTrue);
    expect(primaryNode.hasFocus, isFalse);
  });

  testWidgets(
    'focusTabPrimaryEntry ignores remembered focus and uses the primary node',
    (tester) async {
      final orchestrator = DefaultFocusOrchestrator();
      final coordinator = coordinatorFor(orchestrator);
      final primaryNode = FocusNode(debugLabel: 'primary');
      final rememberedNode = FocusNode(debugLabel: 'remembered');
      addTearDown(primaryNode.dispose);
      addTearDown(rememberedNode.dispose);
      await pumpFocusNodes(tester, [primaryNode, rememberedNode]);

      registerTabRegion(
        orchestrator,
        ShellTab.search,
        primaryNode: primaryNode,
      );
      orchestrator.rememberFocusedNode(
        AppFocusRegionId.searchInput,
        rememberedNode,
      );

      expect(coordinator.focusTabPrimaryEntry(ShellTab.search), isTrue);
      await tester.pump();

      expect(primaryNode.hasFocus, isTrue);
      expect(rememberedNode.hasFocus, isFalse);
    },
  );

  testWidgets(
    'focusTabPrimaryEntry uses a page fallback when the primary is invalid',
    (tester) async {
      final orchestrator = DefaultFocusOrchestrator();
      final coordinator = coordinatorFor(orchestrator);
      final primaryNode = FocusNode(debugLabel: 'primary');
      final fallbackNode = FocusNode(debugLabel: 'fallback');
      addTearDown(primaryNode.dispose);
      addTearDown(fallbackNode.dispose);
      await pumpFocusNodes(tester, [fallbackNode]);

      registerTabRegion(
        orchestrator,
        ShellTab.library,
        primaryNode: primaryNode,
        fallbackNode: fallbackNode,
      );

      expect(coordinator.focusTabPrimaryEntry(ShellTab.library), isTrue);
      await tester.pump();

      expect(fallbackNode.hasFocus, isTrue);
    },
  );

  testWidgets(
    'focusTabPrimaryEntry uses a page-registered region without shell binding',
    (tester) async {
      final orchestrator = DefaultFocusOrchestrator();
      final coordinator = coordinatorFor(orchestrator);
      final pagePrimaryNode = FocusNode(debugLabel: 'page-primary');
      addTearDown(pagePrimaryNode.dispose);
      await pumpFocusNodes(tester, [pagePrimaryNode]);

      orchestrator.registerRegion(
        AppFocusRegionId.searchInput,
        FocusRegionBinding(resolvePrimaryEntryNode: () => pagePrimaryNode),
      );

      expect(coordinator.focusTabPrimaryEntry(ShellTab.search), isTrue);
      await tester.pump();

      expect(pagePrimaryNode.hasFocus, isTrue);
    },
  );

  testWidgets('focusTabEntry returns false when the page region is absent', (
    tester,
  ) async {
    final orchestrator = DefaultFocusOrchestrator();
    final coordinator = coordinatorFor(orchestrator);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));

    expect(coordinator.focusTabEntry(ShellTab.settings), isFalse);
  });

  testWidgets('resolveTabExit moves focus to shellSidebar', (tester) async {
    final orchestrator = DefaultFocusOrchestrator();
    final coordinator = coordinatorFor(orchestrator);
    final sidebarNode = FocusNode(debugLabel: 'sidebar');
    final primaryNode = FocusNode(debugLabel: 'primary');
    addTearDown(sidebarNode.dispose);
    addTearDown(primaryNode.dispose);
    await pumpFocusNodes(tester, [sidebarNode, primaryNode]);

    coordinator.attachSidebar(sidebarNode);
    registerTabRegion(
      orchestrator,
      ShellTab.search,
      primaryNode: primaryNode,
      exitMap: FocusRegionExitMap({
        DirectionalEdge.left: AppFocusRegionId.shellSidebar,
        DirectionalEdge.back: AppFocusRegionId.shellSidebar,
      }),
    );
    primaryNode.requestFocus();

    expect(
      coordinator.resolveTabExit(ShellTab.search, DirectionalEdge.left),
      isTrue,
    );
    await tester.pump();

    expect(sidebarNode.hasFocus, isTrue);
  });
}
