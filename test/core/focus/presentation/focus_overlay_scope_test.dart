import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/focus/application/default_focus_orchestrator.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/presentation/focus_orchestrator_provider.dart';
import 'package:movi/src/core/focus/presentation/focus_overlay_scope.dart';
import 'package:movi/src/core/focus/presentation/focus_region_scope.dart';

void main() {
  Future<void> pumpOverlayHarness(
    WidgetTester tester, {
    required DefaultFocusOrchestrator orchestrator,
    required ValueNotifier<bool> showOverlay,
    required FocusNode initialFocusNode,
    FocusNode? fallbackFocusNode,
    FocusNode? triggerFocusNode,
    AppFocusRegionId? originRegionId,
    AppFocusRegionId? fallbackRegionId = AppFocusRegionId.shellSidebar,
    List<Widget> backgroundChildren = const <Widget>[],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [focusOrchestratorProvider.overrideWithValue(orchestrator)],
        child: MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: showOverlay,
              builder: (context, visible, _) {
                return Column(
                  children: [
                    ...backgroundChildren,
                    if (visible)
                      FocusOverlayScope(
                        initialFocusNode: initialFocusNode,
                        fallbackFocusNode: fallbackFocusNode,
                        triggerFocusNode: triggerFocusNode,
                        originRegionId: originRegionId,
                        fallbackRegionId: fallbackRegionId,
                        child: Focus(
                          focusNode: initialFocusNode,
                          child: const SizedBox(width: 20, height: 20),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> closeOverlay(
    WidgetTester tester,
    ValueNotifier<bool> showOverlay,
  ) async {
    showOverlay.value = false;
    await tester.pump();
    await tester.pump();
  }

  testWidgets('registers dialogPrimary when mounted', (tester) async {
    final orchestrator = DefaultFocusOrchestrator();
    final showOverlay = ValueNotifier<bool>(true);
    final initialFocusNode = FocusNode(debugLabel: 'overlay-initial');
    addTearDown(showOverlay.dispose);
    addTearDown(initialFocusNode.dispose);

    await pumpOverlayHarness(
      tester,
      orchestrator: orchestrator,
      showOverlay: showOverlay,
      initialFocusNode: initialFocusNode,
    );

    expect(
      orchestrator.isRegionRegistered(AppFocusRegionId.dialogPrimary),
      true,
    );
  });

  testWidgets('focuses the initial node when mounted', (tester) async {
    final orchestrator = DefaultFocusOrchestrator();
    final showOverlay = ValueNotifier<bool>(true);
    final initialFocusNode = FocusNode(debugLabel: 'overlay-initial');
    addTearDown(showOverlay.dispose);
    addTearDown(initialFocusNode.dispose);

    await pumpOverlayHarness(
      tester,
      orchestrator: orchestrator,
      showOverlay: showOverlay,
      initialFocusNode: initialFocusNode,
    );
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, same(initialFocusNode));
  });

  testWidgets('restores a valid trigger first when closed', (tester) async {
    final orchestrator = DefaultFocusOrchestrator();
    final showOverlay = ValueNotifier<bool>(true);
    final triggerFocusNode = FocusNode(debugLabel: 'trigger');
    final initialFocusNode = FocusNode(debugLabel: 'overlay-initial');
    addTearDown(showOverlay.dispose);
    addTearDown(triggerFocusNode.dispose);
    addTearDown(initialFocusNode.dispose);

    await pumpOverlayHarness(
      tester,
      orchestrator: orchestrator,
      showOverlay: showOverlay,
      initialFocusNode: initialFocusNode,
      triggerFocusNode: triggerFocusNode,
      backgroundChildren: [
        Focus(
          focusNode: triggerFocusNode,
          child: const SizedBox(width: 20, height: 20),
        ),
      ],
    );
    await tester.pump();

    await closeOverlay(tester, showOverlay);

    expect(FocusManager.instance.primaryFocus, same(triggerFocusNode));
  });

  testWidgets('restores the captured origin region when trigger is absent', (
    tester,
  ) async {
    final orchestrator = DefaultFocusOrchestrator();
    final showOverlay = ValueNotifier<bool>(false);
    final originFocusNode = FocusNode(debugLabel: 'origin');
    final initialFocusNode = FocusNode(debugLabel: 'overlay-initial');
    addTearDown(showOverlay.dispose);
    addTearDown(originFocusNode.dispose);
    addTearDown(initialFocusNode.dispose);

    await pumpOverlayHarness(
      tester,
      orchestrator: orchestrator,
      showOverlay: showOverlay,
      initialFocusNode: initialFocusNode,
      backgroundChildren: [
        FocusRegionScope(
          regionId: AppFocusRegionId.searchInput,
          binding: FocusRegionBinding(
            resolvePrimaryEntryNode: () => originFocusNode,
          ),
          child: Focus(
            focusNode: originFocusNode,
            child: const SizedBox(width: 20, height: 20),
          ),
        ),
      ],
    );
    expect(orchestrator.enterRegion(AppFocusRegionId.searchInput), true);
    await tester.pump();

    showOverlay.value = true;
    await tester.pump();
    await tester.pump();
    await closeOverlay(tester, showOverlay);

    expect(FocusManager.instance.primaryFocus, same(originFocusNode));
  });

  testWidgets('restores the explicit fallback when origin is unavailable', (
    tester,
  ) async {
    final orchestrator = DefaultFocusOrchestrator();
    final showOverlay = ValueNotifier<bool>(true);
    final fallbackFocusNode = FocusNode(debugLabel: 'explicit-fallback');
    final initialFocusNode = FocusNode(debugLabel: 'overlay-initial');
    addTearDown(showOverlay.dispose);
    addTearDown(fallbackFocusNode.dispose);
    addTearDown(initialFocusNode.dispose);

    await pumpOverlayHarness(
      tester,
      orchestrator: orchestrator,
      showOverlay: showOverlay,
      initialFocusNode: initialFocusNode,
      fallbackFocusNode: fallbackFocusNode,
      fallbackRegionId: null,
      backgroundChildren: [
        Focus(
          focusNode: fallbackFocusNode,
          child: const SizedBox(width: 20, height: 20),
        ),
      ],
    );
    await tester.pump();

    await closeOverlay(tester, showOverlay);

    expect(FocusManager.instance.primaryFocus, same(fallbackFocusNode));
  });

  testWidgets('restores shellSidebar when all earlier targets fail', (
    tester,
  ) async {
    final orchestrator = DefaultFocusOrchestrator();
    final showOverlay = ValueNotifier<bool>(true);
    final shellFocusNode = FocusNode(debugLabel: 'shell-sidebar');
    final initialFocusNode = FocusNode(debugLabel: 'overlay-initial');
    addTearDown(showOverlay.dispose);
    addTearDown(shellFocusNode.dispose);
    addTearDown(initialFocusNode.dispose);

    await pumpOverlayHarness(
      tester,
      orchestrator: orchestrator,
      showOverlay: showOverlay,
      initialFocusNode: initialFocusNode,
      backgroundChildren: [
        FocusRegionScope(
          regionId: AppFocusRegionId.shellSidebar,
          binding: FocusRegionBinding(
            resolvePrimaryEntryNode: () => shellFocusNode,
            resolveFallbackEntryNode: () => shellFocusNode,
          ),
          child: Focus(
            focusNode: shellFocusNode,
            child: const SizedBox(width: 20, height: 20),
          ),
        ),
      ],
    );
    await tester.pump();

    await closeOverlay(tester, showOverlay);

    expect(FocusManager.instance.primaryFocus, same(shellFocusNode));
  });

  testWidgets(
    'does not steal focus already moved outside the closing overlay',
    (tester) async {
      final orchestrator = DefaultFocusOrchestrator();
      final showOverlay = ValueNotifier<bool>(true);
      final triggerFocusNode = FocusNode(debugLabel: 'trigger');
      final outsideFocusNode = FocusNode(debugLabel: 'outside');
      final initialFocusNode = FocusNode(debugLabel: 'overlay-initial');
      addTearDown(showOverlay.dispose);
      addTearDown(triggerFocusNode.dispose);
      addTearDown(outsideFocusNode.dispose);
      addTearDown(initialFocusNode.dispose);

      await pumpOverlayHarness(
        tester,
        orchestrator: orchestrator,
        showOverlay: showOverlay,
        initialFocusNode: initialFocusNode,
        triggerFocusNode: triggerFocusNode,
        backgroundChildren: [
          Focus(
            focusNode: triggerFocusNode,
            child: const SizedBox(width: 20, height: 20),
          ),
          Focus(
            focusNode: outsideFocusNode,
            child: const SizedBox(width: 20, height: 20),
          ),
        ],
      );
      await tester.pump();

      showOverlay.value = false;
      outsideFocusNode.requestFocus();
      await tester.pump();
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, same(outsideFocusNode));
    },
  );

  testWidgets('unregisters dialogPrimary after dispose', (tester) async {
    final orchestrator = DefaultFocusOrchestrator();
    final showOverlay = ValueNotifier<bool>(true);
    final initialFocusNode = FocusNode(debugLabel: 'overlay-initial');
    addTearDown(showOverlay.dispose);
    addTearDown(initialFocusNode.dispose);

    await pumpOverlayHarness(
      tester,
      orchestrator: orchestrator,
      showOverlay: showOverlay,
      initialFocusNode: initialFocusNode,
    );
    expect(
      orchestrator.isRegionRegistered(AppFocusRegionId.dialogPrimary),
      true,
    );

    await closeOverlay(tester, showOverlay);

    expect(
      orchestrator.isRegionRegistered(AppFocusRegionId.dialogPrimary),
      false,
    );
  });
}
