import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/widgets/movi_ellipsis_text.dart';

void main() {
  const style = TextStyle(fontSize: 16, height: 1.2);

  testWidgets('shows short text fully', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MoviEllipsisText(
            text: 'Short',
            style: style,
            maxWidth: 200,
          ),
        ),
      ),
    );

    final textWidget = tester.widget<Text>(find.text('Short'));
    expect(textWidget.data, 'Short');
    expect(textWidget.maxLines, 1);
    expect(textWidget.overflow, TextOverflow.ellipsis);
    expect(textWidget.softWrap, false);
  });

  testWidgets('uses ellipsis overflow for long text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MoviEllipsisText(
            text: 'A' * 200,
            style: style.copyWith(fontSize: 24),
            maxWidth: 40,
          ),
        ),
      ),
    );

    final textFinder = find.byType(Text);
    expect(textFinder, findsOneWidget);
    final textWidget = tester.widget<Text>(textFinder);
    expect(textWidget.maxLines, 1);
    expect(textWidget.overflow, TextOverflow.ellipsis);
    expect(textWidget.softWrap, false);
  });
}
