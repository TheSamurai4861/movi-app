import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/responsive/presentation/widgets/responsive_layout.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';

Widget _desktopHarness(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 1600,
        height: 900,
        child: ResponsiveLayout(child: child),
      ),
    ),
  );
}

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });

  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  testWidgets('activates from tap and keyboard intent', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final focusNode = FocusNode(debugLabel: 'action');
    addTearDown(focusNode.dispose);
    var activations = 0;

    await tester.pumpWidget(
      _desktopHarness(
        Center(
          child: MoviFocusableAction(
            focusNode: focusNode,
            onPressed: () => activations += 1,
            builder: (_, __) =>
                const SizedBox(width: 120, height: 48, child: Text('Action')),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Action'));
    await tester.pump();
    expect(activations, 1);

    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(activations, 2);
  });

  testWidgets('passes focus hover and pressed states to the builder', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final focusNode = FocusNode(debugLabel: 'action');
    addTearDown(focusNode.dispose);
    MoviInteractiveState? lastState;

    await tester.pumpWidget(
      _desktopHarness(
        Center(
          child: MoviFocusableAction(
            focusNode: focusNode,
            onPressed: () {},
            builder: (_, state) {
              lastState = state;
              return const SizedBox(width: 120, height: 48);
            },
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, true);
    expect(lastState?.focused, true);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(MoviFocusableAction)));
    await tester.pump();
    expect(lastState?.hovered, true);

    final touch = await tester.startGesture(
      tester.getCenter(find.byType(MoviFocusableAction)),
    );
    await tester.pump();
    expect(lastState?.pressed, true);

    await touch.up();
    await tester.pump();
    expect(lastState?.pressed, false);
  });

  testWidgets('keeps semantic contract', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _desktopHarness(
        Center(
          child: MoviFocusableAction(
            onPressed: () {},
            semanticLabel: 'Semantic action',
            toggled: true,
            builder: (_, __) => const SizedBox(width: 120, height: 48),
          ),
        ),
      ),
    );

    final semanticsFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics && widget.properties.label == 'Semantic action',
    );
    final semantics = tester.widget<Semantics>(semanticsFinder);

    expect(semantics.properties.label, 'Semantic action');
    expect(semantics.properties.button, true);
    expect(semantics.properties.enabled, true);
    expect(semantics.properties.toggled, true);
  });

  testWidgets('does not scroll when focused without ensure-visible wrapper', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = ScrollController();
    final focusNode = FocusNode(debugLabel: 'target');
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      _desktopHarness(
        SingleChildScrollView(
          controller: controller,
          child: Column(
            children: [
              const SizedBox(height: 1200),
              MoviFocusableAction(
                focusNode: focusNode,
                onPressed: () {},
                builder: (_, __) => const SizedBox(width: 120, height: 48),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(controller.offset, 0);

    focusNode.requestFocus();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(controller.offset, 0);
  });
}
