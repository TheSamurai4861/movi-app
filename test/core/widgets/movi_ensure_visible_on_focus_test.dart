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
    'vertical ensureVisible uses the outermost scrollable ancestor',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final outerController = ScrollController();
      final childFocusNode = FocusNode(debugLabel: 'nested_target');
      addTearDown(outerController.dispose);
      addTearDown(childFocusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              controller: outerController,
              children: [
                const SizedBox(height: 1200),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    if (index != 5) {
                      return const SizedBox(height: 80);
                    }
                    return MoviEnsureVisibleOnFocus(
                      child: MoviFocusableAction(
                        focusNode: childFocusNode,
                        onPressed: () {},
                        builder: (_, __) => const SizedBox(
                          width: double.infinity,
                          height: 80,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 200),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      outerController.jumpTo(outerController.position.maxScrollExtent);
      await tester.pump();
      final offsetBeforeFocus = outerController.offset;

      childFocusNode.requestFocus();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Must not jump back to the top when focusing a nested grid item.
      expect(outerController.offset, greaterThan(100));
      expect(outerController.offset, greaterThanOrEqualTo(offsetBeforeFocus - 80));
    },
  );

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

  testWidgets(
    'minimal reveal policy does not scroll when target is already visible',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final scrollController = ScrollController();
      final childFocusNode = FocusNode(debugLabel: 'visible_target');
      addTearDown(scrollController.dispose);
      addTearDown(childFocusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              controller: scrollController,
              children: [
                const SizedBox(height: 400),
                MoviFocusRevealScope(
                  policy: MoviVerticalRevealPolicy.minimal,
                  child: MoviEnsureVisibleOnFocus(
                    child: MoviFocusableAction(
                      focusNode: childFocusNode,
                      onPressed: () {},
                      builder: (_, __) => const SizedBox(
                        width: 200,
                        height: 80,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 400),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      scrollController.jumpTo(320);
      await tester.pump();
      final offsetBeforeFocus = scrollController.offset;

      childFocusNode.requestFocus();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(scrollController.offset, closeTo(offsetBeforeFocus, 0.01));
    },
  );

  testWidgets(
    'minimal reveal policy scrolls down when target is below the viewport',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final scrollController = ScrollController();
      final childFocusNode = FocusNode(debugLabel: 'below_target');
      addTearDown(scrollController.dispose);
      addTearDown(childFocusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              controller: scrollController,
              children: [
                const SizedBox(height: 900),
                MoviFocusRevealScope(
                  policy: MoviVerticalRevealPolicy.minimal,
                  child: MoviEnsureVisibleOnFocus(
                    child: Focus(
                      focusNode: childFocusNode,
                      child: const SizedBox(
                        width: 200,
                        height: 80,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 200),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      scrollController.jumpTo(0);
      await tester.pump();
      expect(scrollController.offset, 0);

      childFocusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(scrollController.offset, greaterThan(100));
    },
  );

  testWidgets(
    'anchor reveal policy keeps explicit vertical alignment behavior',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final scrollController = ScrollController();
      final childFocusNode = FocusNode(debugLabel: 'anchor_target');
      addTearDown(scrollController.dispose);
      addTearDown(childFocusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              controller: scrollController,
              children: [
                const SizedBox(height: 1200),
                MoviEnsureVisibleOnFocus(
                  verticalAlignment: 0.22,
                  verticalRevealPolicy: MoviVerticalRevealPolicy.anchor,
                  child: MoviFocusableAction(
                    focusNode: childFocusNode,
                    onPressed: () {},
                    builder: (_, __) => const SizedBox(
                      width: 200,
                      height: 80,
                    ),
                  ),
                ),
                const SizedBox(height: 200),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
      await tester.pump();
      final offsetBeforeFocus = scrollController.offset;

      childFocusNode.requestFocus();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump();

      expect(scrollController.offset, lessThan(offsetBeforeFocus));
      expect(scrollController.offset, greaterThan(200));
    },
  );
}
