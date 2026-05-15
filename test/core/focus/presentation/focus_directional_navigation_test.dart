import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/focus/presentation/focus_directional_navigation.dart';

KeyDownEvent _arrow(LogicalKeyboardKey logicalKey) {
  final physicalKey = switch (logicalKey) {
    LogicalKeyboardKey.arrowLeft => PhysicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight => PhysicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.arrowUp => PhysicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown => PhysicalKeyboardKey.arrowDown,
    _ => PhysicalKeyboardKey(0),
  };
  return KeyDownEvent(
    physicalKey: physicalKey,
    logicalKey: logicalKey,
    timeStamp: Duration.zero,
  );
}

void main() {
  group('handleVerticalListKey', () {
    testWidgets('blocks left and right without changing focus', (tester) async {
      final nodes = List<FocusNode>.generate(
        3,
        (index) => FocusNode(debugLabel: 'node$index'),
      );
      final up = FocusNode(debugLabel: 'up');
      final down = FocusNode(debugLabel: 'down');
      addTearDown(() {
        for (final node in nodes) {
          node.dispose();
        }
        up.dispose();
        down.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Focus(
                  focusNode: up,
                  child: const SizedBox(width: 10, height: 10),
                ),
                for (final node in nodes)
                  Focus(
                    focusNode: node,
                    child: const SizedBox(width: 10, height: 10),
                  ),
                Focus(
                  focusNode: down,
                  child: const SizedBox(width: 10, height: 10),
                ),
              ],
            ),
          ),
        ),
      );

      nodes[1].requestFocus();
      await tester.pump();
      expect(nodes[1].hasFocus, isTrue);

      for (final key in [
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowRight,
      ]) {
        final result = FocusDirectionalNavigation.handleVerticalListKey(
          _arrow(key),
          index: 1,
          nodes: nodes,
          up: up,
          down: down,
        );
        expect(result, KeyEventResult.handled);
        await tester.pump();
        expect(nodes[1].hasFocus, isTrue);
      }
    });

    testWidgets('arrow up on first item focuses external up', (tester) async {
      final nodes = List<FocusNode>.generate(3, (_) => FocusNode());
      final up = FocusNode();
      final down = FocusNode();
      addTearDown(() {
        for (final node in nodes) {
          node.dispose();
        }
        up.dispose();
        down.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Focus(focusNode: up, child: const SizedBox(height: 10)),
                for (final node in nodes)
                  Focus(focusNode: node, child: const SizedBox(height: 10)),
                Focus(focusNode: down, child: const SizedBox(height: 10)),
              ],
            ),
          ),
        ),
      );

      nodes[0].requestFocus();
      await tester.pump();

      final result = FocusDirectionalNavigation.handleVerticalListKey(
        _arrow(LogicalKeyboardKey.arrowUp),
        index: 0,
        nodes: nodes,
        up: up,
        down: down,
      );

      expect(result, KeyEventResult.handled);
      await tester.pump();
      expect(up.hasFocus, isTrue);
    });

    testWidgets('arrow up on middle item focuses previous node', (
      tester,
    ) async {
      final nodes = List<FocusNode>.generate(3, (_) => FocusNode());
      final up = FocusNode();
      final down = FocusNode();
      addTearDown(() {
        for (final node in nodes) {
          node.dispose();
        }
        up.dispose();
        down.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Focus(focusNode: up, child: const SizedBox(height: 10)),
                for (final node in nodes)
                  Focus(focusNode: node, child: const SizedBox(height: 10)),
                Focus(focusNode: down, child: const SizedBox(height: 10)),
              ],
            ),
          ),
        ),
      );

      nodes[1].requestFocus();
      await tester.pump();

      final result = FocusDirectionalNavigation.handleVerticalListKey(
        _arrow(LogicalKeyboardKey.arrowUp),
        index: 1,
        nodes: nodes,
        up: up,
        down: down,
      );

      expect(result, KeyEventResult.handled);
      await tester.pump();
      expect(nodes[0].hasFocus, isTrue);
    });

    testWidgets('arrow down on middle item focuses next node', (tester) async {
      final nodes = List<FocusNode>.generate(3, (_) => FocusNode());
      final up = FocusNode();
      final down = FocusNode();
      addTearDown(() {
        for (final node in nodes) {
          node.dispose();
        }
        up.dispose();
        down.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Focus(focusNode: up, child: const SizedBox(height: 10)),
                for (final node in nodes)
                  Focus(focusNode: node, child: const SizedBox(height: 10)),
                Focus(focusNode: down, child: const SizedBox(height: 10)),
              ],
            ),
          ),
        ),
      );

      nodes[0].requestFocus();
      await tester.pump();

      final result = FocusDirectionalNavigation.handleVerticalListKey(
        _arrow(LogicalKeyboardKey.arrowDown),
        index: 0,
        nodes: nodes,
        up: up,
        down: down,
      );

      expect(result, KeyEventResult.handled);
      await tester.pump();
      expect(nodes[1].hasFocus, isTrue);
    });

    testWidgets('arrow down on last item focuses external down', (
      tester,
    ) async {
      final nodes = List<FocusNode>.generate(3, (_) => FocusNode());
      final up = FocusNode();
      final down = FocusNode();
      addTearDown(() {
        for (final node in nodes) {
          node.dispose();
        }
        up.dispose();
        down.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Focus(focusNode: up, child: const SizedBox(height: 10)),
                for (final node in nodes)
                  Focus(focusNode: node, child: const SizedBox(height: 10)),
                Focus(focusNode: down, child: const SizedBox(height: 10)),
              ],
            ),
          ),
        ),
      );

      nodes[2].requestFocus();
      await tester.pump();

      final result = FocusDirectionalNavigation.handleVerticalListKey(
        _arrow(LogicalKeyboardKey.arrowDown),
        index: 2,
        nodes: nodes,
        up: up,
        down: down,
      );

      expect(result, KeyEventResult.handled);
      await tester.pump();
      expect(down.hasFocus, isTrue);
    });
  });
}
