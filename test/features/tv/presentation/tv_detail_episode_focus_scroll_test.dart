import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';

class _SeasonToEpisodeHarness extends StatefulWidget {
  const _SeasonToEpisodeHarness({
    required this.verticalController,
    required this.horizontalController,
    required this.seasonTabsFocusNode,
    required this.episodeFocusNodes,
  });

  final ScrollController verticalController;
  final ScrollController horizontalController;
  final FocusNode seasonTabsFocusNode;
  final List<FocusNode> episodeFocusNodes;

  @override
  State<_SeasonToEpisodeHarness> createState() =>
      _SeasonToEpisodeHarnessState();
}

class _SeasonToEpisodeHarnessState extends State<_SeasonToEpisodeHarness> {
  KeyEventResult _handleSeasonTabsKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.arrowDown) {
      return KeyEventResult.ignored;
    }

    widget.verticalController.jumpTo(
      widget.verticalController.position.maxScrollExtent,
    );
    widget.episodeFocusNodes.first.requestFocus();
    return KeyEventResult.handled;
  }

  KeyEventResult _handleEpisodeKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft && index > 0) {
      widget.episodeFocusNodes[index - 1].requestFocus();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
        index < widget.episodeFocusNodes.length - 1) {
      widget.episodeFocusNodes[index + 1].requestFocus();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      widget.seasonTabsFocusNode.requestFocus();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          controller: widget.verticalController,
          child: SizedBox(
            height: 1700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 120),
                Focus(
                  focusNode: widget.seasonTabsFocusNode,
                  onKeyEvent: (_, event) => _handleSeasonTabsKey(event),
                  child: const SizedBox(
                    width: 240,
                    height: 56,
                    child: ColoredBox(color: Colors.teal),
                  ),
                ),
                const SizedBox(height: 900),
                SizedBox(
                  height: 160,
                  child: Builder(
                    builder: (listContext) {
                      return MoviVerticalEnsureVisibleTarget(
                        targetContext: listContext,
                        child: SingleChildScrollView(
                          controller: widget.horizontalController,
                          scrollDirection: Axis.horizontal,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: List<Widget>.generate(
                                widget.episodeFocusNodes.length,
                                (index) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      right:
                                          index ==
                                              widget.episodeFocusNodes.length -
                                                  1
                                          ? 0
                                          : 16,
                                    ),
                                    child: Focus(
                                      canRequestFocus: false,
                                      onKeyEvent: (_, event) =>
                                          _handleEpisodeKey(index, event),
                                      child: MoviEnsureVisibleOnFocus(
                                        enableVerticalScroll: false,
                                        child: Focus(
                                          focusNode:
                                              widget.episodeFocusNodes[index],
                                          child: Container(
                                            width: 320,
                                            height: 140,
                                            decoration: BoxDecoration(
                                              color: Colors.blueGrey,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets(
    'season tabs down keeps page at bottom and episode navigation does not move it back up',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final verticalController = ScrollController();
      final horizontalController = ScrollController();
      final seasonTabsFocusNode = FocusNode(debugLabel: 'season-tabs');
      final episodeFocusNodes = List<FocusNode>.generate(
        6,
        (index) => FocusNode(debugLabel: 'episode-$index'),
      );

      addTearDown(verticalController.dispose);
      addTearDown(horizontalController.dispose);
      addTearDown(seasonTabsFocusNode.dispose);
      addTearDown(() {
        for (final node in episodeFocusNodes) {
          node.dispose();
        }
      });

      await tester.pumpWidget(
        _SeasonToEpisodeHarness(
          verticalController: verticalController,
          horizontalController: horizontalController,
          seasonTabsFocusNode: seasonTabsFocusNode,
          episodeFocusNodes: episodeFocusNodes,
        ),
      );

      await tester.pumpAndSettle();
      seasonTabsFocusNode.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      final expectedBottomOffset = verticalController.position.maxScrollExtent;
      expect(verticalController.offset, closeTo(expectedBottomOffset, 0.01));

      if (!episodeFocusNodes.first.hasFocus) {
        episodeFocusNodes.first.requestFocus();
        await tester.pump();
      }

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(episodeFocusNodes[3].hasFocus, isTrue);
      expect(verticalController.offset, closeTo(expectedBottomOffset, 0.01));
    },
  );
}
