import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/widgets/movi_media_grid.dart';

void main() {
  testWidgets('focusRequestId focuses requested grid index', (tester) async {
    final capturedNodes = <int, FocusNode>{};
    var focusRequestId = 0;
    int? focusRequestIndex;

    Widget buildGrid() {
      return MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              MoviMediaGrid(
                itemCount: 6,
                focusRequestId: focusRequestId,
                focusRequestIndex: focusRequestIndex,
                itemBuilder: (context, index, focusNode, cardWidth, posterHeight) {
                  capturedNodes[index] = focusNode;
                  return SizedBox(
                    width: cardWidth,
                    height: posterHeight,
                    child: TextButton(
                      focusNode: focusNode,
                      onPressed: () {},
                      child: Text('item-$index'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(buildGrid());
    await tester.pump();

    capturedNodes[0]!.requestFocus();
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, capturedNodes[0]);

    focusRequestId = 1;
    focusRequestIndex = 4;
    await tester.pumpWidget(buildGrid());
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, capturedNodes[4]);
  });
}
