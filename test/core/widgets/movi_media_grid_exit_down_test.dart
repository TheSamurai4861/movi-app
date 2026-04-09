import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/widgets/movi_media_grid.dart';

void main() {
  testWidgets('arrow down on last row triggers onExitDown', (tester) async {
    var exitDownCalls = 0;
    final nodes = <int, FocusNode>{};

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              MoviMediaGrid(
                itemCount: 1,
                onExitDown: () {
                  exitDownCalls++;
                  return true;
                },
                itemBuilder: (context, index, focusNode, cardWidth, posterHeight) {
                  nodes[index] = focusNode;
                  return SizedBox(
                    width: cardWidth,
                    height: posterHeight,
                    child: TextButton(
                      focusNode: focusNode,
                      onPressed: () {},
                      child: const Text('item'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    nodes[0]!.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(exitDownCalls, 1);
    expect(FocusManager.instance.primaryFocus, equals(nodes[0]));
  });
}
