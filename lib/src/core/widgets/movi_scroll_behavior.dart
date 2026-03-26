import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Global scroll behavior used by Movi.
///
/// On desktop, Flutter does not enable mouse drag on scrollables by default.
/// We opt in globally so horizontal media rails can be dragged with the mouse
/// the same way they already work with touch.
class MoviScrollBehavior extends MaterialScrollBehavior {
  const MoviScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.trackpad,
  };
}
