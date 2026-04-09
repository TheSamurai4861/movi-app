import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';

void main() {
  testWidgets('leading edge left is ignored by default', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final childFocusNode = FocusNode(debugLabel: 'child');
    var parentEvents = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Focus(
            canRequestFocus: false,
            onKeyEvent: (_, event) {
              if (event is! KeyDownEvent) {
                return KeyEventResult.ignored;
              }
              parentEvents += 1;
              return KeyEventResult.handled;
            },
            child: MoviEnsureVisibleOnFocus(
              isLeadingEdge: true,
              child: Focus(
                focusNode: childFocusNode,
                child: const SizedBox(width: 80, height: 40),
              ),
            ),
          ),
        ),
      ),
    );

    childFocusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();

    expect(parentEvents, greaterThan(0));
    childFocusNode.dispose();
  });

  testWidgets('leading edge left can be consumed', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final childFocusNode = FocusNode(debugLabel: 'child');
    var parentEvents = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Focus(
            canRequestFocus: false,
            onKeyEvent: (_, event) {
              if (event is! KeyDownEvent) {
                return KeyEventResult.ignored;
              }
              parentEvents += 1;
              return KeyEventResult.handled;
            },
            child: MoviEnsureVisibleOnFocus(
              isLeadingEdge: true,
              consumeBackwardEdgeKey: true,
              child: Focus(
                focusNode: childFocusNode,
                child: const SizedBox(width: 80, height: 40),
              ),
            ),
          ),
        ),
      ),
    );

    childFocusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();

    expect(parentEvents, 0);
    childFocusNode.dispose();
  });

  testWidgets(
    'vertical scrolling can be disabled without moving the parent scrollable',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final verticalController = ScrollController();
      final horizontalController = ScrollController();
      final childFocusNode = FocusNode(debugLabel: 'target');
      addTearDown(verticalController.dispose);
      addTearDown(horizontalController.dispose);
      addTearDown(childFocusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              controller: verticalController,
              child: SizedBox(
                height: 1600,
                child: Column(
                  children: [
                    const SizedBox(height: 1100),
                    SizedBox(
                      height: 140,
                      child: SingleChildScrollView(
                        controller: horizontalController,
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List<Widget>.generate(8, (index) {
                            final card = SizedBox(
                              width: 320,
                              height: 120,
                              child: ColoredBox(
                                color: index == 7
                                    ? Colors.orange
                                    : Colors.blueGrey,
                              ),
                            );
                            if (index != 7) {
                              return card;
                            }
                            return MoviEnsureVisibleOnFocus(
                              enableVerticalScroll: false,
                              child: MoviFocusableAction(
                                focusNode: childFocusNode,
                                onPressed: () {},
                                builder: (_, __) => card,
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      verticalController.jumpTo(verticalController.position.maxScrollExtent);
      await tester.pump();
      final expectedVerticalOffset = verticalController.offset;

      childFocusNode.requestFocus();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(verticalController.offset, closeTo(expectedVerticalOffset, 0.01));
    },
  );
}
