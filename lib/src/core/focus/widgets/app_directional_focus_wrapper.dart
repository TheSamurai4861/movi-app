import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:movi/src/core/focus/presentation/focus_directional_navigation.dart';
import 'package:movi/src/core/widgets/movi_ensure_visible_on_focus.dart';

class AppDirectionalFocusWrapper extends StatelessWidget {
  const AppDirectionalFocusWrapper({
    super.key,
    required this.child,
    this.verticalAlignment = 0.4,
    this.horizontalAlignment,
    this.nextDownFocus,
    this.nextUpFocus,
    this.nextLeftFocus,
    this.nextRightFocus,
    this.blockUp = false,
    this.blockDown = false,
    this.blockLeft = true,
    this.blockRight = true,
    this.enableVerticalScroll = true,
  });

  final Widget child;
  final double verticalAlignment;
  final double? horizontalAlignment;
  final FocusNode? nextDownFocus;
  final FocusNode? nextUpFocus;
  final FocusNode? nextLeftFocus;
  final FocusNode? nextRightFocus;
  final bool blockUp;
  final bool blockDown;
  final bool blockLeft;
  final bool blockRight;
  final bool enableVerticalScroll;

  Map<ShortcutActivator, VoidCallback> _buildBindings() {
    final bindings = <ShortcutActivator, VoidCallback>{};

    if (nextUpFocus != null) {
      bindings[const SingleActivator(LogicalKeyboardKey.arrowUp)] =
          () => FocusDirectionalNavigation.requestFocus(nextUpFocus);
    }

    if (nextDownFocus != null) {
      bindings[const SingleActivator(LogicalKeyboardKey.arrowDown)] =
          () => FocusDirectionalNavigation.requestFocus(nextDownFocus);
    }

    if (nextLeftFocus != null) {
      bindings[const SingleActivator(LogicalKeyboardKey.arrowLeft)] =
          () => FocusDirectionalNavigation.requestFocus(nextLeftFocus);
    }

    if (nextRightFocus != null) {
      bindings[const SingleActivator(LogicalKeyboardKey.arrowRight)] =
          () => FocusDirectionalNavigation.requestFocus(nextRightFocus);
    }

    return bindings;
  }

  @override
  Widget build(BuildContext context) {
    final bindings = _buildBindings();

    Widget content = Focus(
      canRequestFocus: false,
      onKeyEvent: (_, event) => FocusDirectionalNavigation.handleDirectionalKey(
        event,
        up: nextUpFocus,
        down: nextDownFocus,
        left: nextLeftFocus,
        right: nextRightFocus,
        blockUp: blockUp,
        blockDown: blockDown,
        blockLeft: blockLeft,
        blockRight: blockRight,
      ),
      child: child,
    );

    if (bindings.isNotEmpty) {
      content = CallbackShortcuts(bindings: bindings, child: content);
    }

    return MoviEnsureVisibleOnFocus(
      verticalAlignment: verticalAlignment,
      horizontalAlignment: horizontalAlignment,
      enableVerticalScroll: enableVerticalScroll,
      child: content,
    );
  }
}