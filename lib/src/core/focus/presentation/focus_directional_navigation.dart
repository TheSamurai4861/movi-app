import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class FocusDirectionalNavigation {
  const FocusDirectionalNavigation._();

  static KeyEventResult handleBackKey(
    KeyEvent event, {
    required bool Function() onBack,
  }) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      return onBack() ? KeyEventResult.handled : KeyEventResult.ignored;
    }

    return KeyEventResult.ignored;
  }

  static bool requestFocus(FocusNode? node) {
    if (node == null || !node.canRequestFocus || node.context == null) {
      return false;
    }
    node.requestFocus();
    return true;
  }

  static KeyEventResult handleDirectionalKey(
    KeyEvent event, {
    FocusNode? left,
    FocusNode? right,
    FocusNode? up,
    FocusNode? down,
    bool blockLeft = true,
    bool blockRight = true,
    bool blockUp = true,
    bool blockDown = true,
  }) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        if (requestFocus(left)) return KeyEventResult.handled;
        return blockLeft ? KeyEventResult.handled : KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowRight:
        if (requestFocus(right)) return KeyEventResult.handled;
        return blockRight ? KeyEventResult.handled : KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowUp:
        if (requestFocus(up)) return KeyEventResult.handled;
        return blockUp ? KeyEventResult.handled : KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowDown:
        if (requestFocus(down)) return KeyEventResult.handled;
        return blockDown ? KeyEventResult.handled : KeyEventResult.ignored;
    }

    return KeyEventResult.ignored;
  }

  static KeyEventResult handleDirectionalTransition(
    KeyEvent event, {
    bool Function()? onLeft,
    bool Function()? onRight,
    bool Function()? onUp,
    bool Function()? onDown,
    bool blockLeft = true,
    bool blockRight = true,
    bool blockUp = true,
    bool blockDown = true,
  }) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        if (onLeft?.call() ?? false) {
          return KeyEventResult.handled;
        }
        return blockLeft ? KeyEventResult.handled : KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowRight:
        if (onRight?.call() ?? false) {
          return KeyEventResult.handled;
        }
        return blockRight ? KeyEventResult.handled : KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowUp:
        if (onUp?.call() ?? false) {
          return KeyEventResult.handled;
        }
        return blockUp ? KeyEventResult.handled : KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowDown:
        if (onDown?.call() ?? false) {
          return KeyEventResult.handled;
        }
        return blockDown ? KeyEventResult.handled : KeyEventResult.ignored;
    }

    return KeyEventResult.ignored;
  }


  static KeyEventResult handleHorizontalGroupKey(
    KeyEvent event, {
    required int index,
    required List<FocusNode> nodes,
    FocusNode? up,
    FocusNode? down,
  }) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        if (index == 0) {
          return KeyEventResult.handled;
        }
        return requestFocus(nodes[index - 1])
            ? KeyEventResult.handled
            : KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowRight:
        if (index >= nodes.length - 1) {
          return KeyEventResult.handled;
        }
        return requestFocus(nodes[index + 1])
            ? KeyEventResult.handled
            : KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowUp:
        return requestFocus(up)
            ? KeyEventResult.handled
            : KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowDown:
        return requestFocus(down)
            ? KeyEventResult.handled
            : KeyEventResult.ignored;
    }

    return KeyEventResult.ignored;
  }

  static KeyEventResult handleVerticalListKey(
    KeyEvent event, {
    required int index,
    required List<FocusNode> nodes,
    FocusNode? up,
    FocusNode? down,
  }) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.arrowRight:
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        final target = index == 0 ? up : nodes[index - 1];
        return requestFocus(target)
            ? KeyEventResult.handled
            : KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowDown:
        final target = index >= nodes.length - 1 ? down : nodes[index + 1];
        return requestFocus(target)
            ? KeyEventResult.handled
            : KeyEventResult.ignored;
    }

    return KeyEventResult.ignored;
  }

  static KeyEventResult handleSliderKey(
    KeyEvent event, {
    FocusNode? up,
    FocusNode? down,
  }) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        return requestFocus(up)
            ? KeyEventResult.handled
            : KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowDown:
        return requestFocus(down)
            ? KeyEventResult.handled
            : KeyEventResult.ignored;
    }

    return KeyEventResult.ignored;
  }
}
