import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/widgets/subtitle_playback_layout.dart';

void main() {
  testWidgets('uses lower bottom padding on phone landscape with controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late double bottomPadding;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(844, 390),
            padding: EdgeInsets.only(bottom: 12),
          ),
          child: Builder(
            builder: (context) {
              bottomPadding = SubtitlePlaybackLayout.bottomPadding(
                context,
                showPlayerControls: true,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(bottomPadding, 46);
  });

  testWidgets('uses lower bottom padding on phone landscape without controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late double bottomPadding;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(844, 390),
            padding: EdgeInsets.only(bottom: 12),
          ),
          child: Builder(
            builder: (context) {
              bottomPadding = SubtitlePlaybackLayout.bottomPadding(
                context,
                showPlayerControls: false,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(bottomPadding, 32);
  });
}
