import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class MoviDirectionalFocusGroup extends StatelessWidget {
  const MoviDirectionalFocusGroup({
    super.key,
    required this.child,
    required this.nodes,
    required this.axis,
    this.debugLabel,
  });

  final Widget child;
  final List<FocusNode> nodes;
  final Axis axis;
  final String? debugLabel;

  static KeyEventResult handleSimpleDirectionalFocus({
    required KeyEvent event,
    required List<FocusNode> nodes,
    required int currentIndex,
    required Axis axis,
  }) {
    if (event is! KeyDownEvent || nodes.isEmpty) {
      return KeyEventResult.ignored;
    }

    final isBackward =
        (axis == Axis.horizontal &&
            event.logicalKey == LogicalKeyboardKey.arrowLeft) ||
        (axis == Axis.vertical &&
            event.logicalKey == LogicalKeyboardKey.arrowUp);
    final isForward =
        (axis == Axis.horizontal &&
            event.logicalKey == LogicalKeyboardKey.arrowRight) ||
        (axis == Axis.vertical &&
            event.logicalKey == LogicalKeyboardKey.arrowDown);

    if (!isBackward && !isForward) {
      return KeyEventResult.ignored;
    }

    final nextIndex = isBackward ? currentIndex - 1 : currentIndex + 1;
    if (nextIndex < 0 || nextIndex >= nodes.length) {
      return KeyEventResult.ignored;
    }

    final nextNode = nodes[nextIndex];
    if (!nextNode.canRequestFocus || nextNode.context == null) {
      return KeyEventResult.ignored;
    }

    nextNode.requestFocus();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(child: child);
  }
}
