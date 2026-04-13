import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/focus/application/default_focus_orchestrator.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/movi_overlay_focus_scope.dart';
import 'package:movi/src/core/focus/presentation/focus_orchestrator_provider.dart';
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
    AppFocusRegionId overlayRegionId = AppFocusRegionId.dialogPrimary,
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
                      MoviOverlayFocusScope(
                        initialFocusNode: initialFocusNode,
                        fallbackFocusNode: fallbackFocusNode,
                        triggerFocusNode: triggerFocusNode,
                        originRegionId: originRegionId,
                        overlayRegionId: overlayRegionId,
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

  testWidgets('forwards a custom overlay region id', (tester) async {
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
      overlayRegionId: AppFocusRegionId.settingsPrimary,
    );

    expect(
      orchestrator.isRegionRegistered(AppFocusRegionId.settingsPrimary),
      true,
    );
    expect(
      orchestrator.isRegionRegistered(AppFocusRegionId.dialogPrimary),
      false,
    );
  });

  testWidgets('forwards an explicit fallback region id on close', (tester) async {
    final orchestrator = DefaultFocusOrchestrator();
    final showOverlay = ValueNotifier<bool>(true);
    final initialFocusNode = FocusNode(debugLabel: 'overlay-initial');
    final fallbackRegionFocusNode = FocusNode(debugLabel: 'settings-primary');
    addTearDown(showOverlay.dispose);
    addTearDown(initialFocusNode.dispose);
    addTearDown(fallbackRegionFocusNode.dispose);

    await pumpOverlayHarness(
      tester,
      orchestrator: orchestrator,
      showOverlay: showOverlay,
      initialFocusNode: initialFocusNode,
      fallbackRegionId: AppFocusRegionId.settingsPrimary,
      backgroundChildren: [
        FocusRegionScope(
          regionId: AppFocusRegionId.settingsPrimary,
          binding: FocusRegionBinding(
            resolvePrimaryEntryNode: () => fallbackRegionFocusNode,
            resolveFallbackEntryNode: () => fallbackRegionFocusNode,
          ),
          child: Focus(
            focusNode: fallbackRegionFocusNode,
            child: const SizedBox(width: 20, height: 20),
          ),
        ),
      ],
    );
    await tester.pump();

    await closeOverlay(tester, showOverlay);

    expect(FocusManager.instance.primaryFocus, same(fallbackRegionFocusNode));
  });
}
