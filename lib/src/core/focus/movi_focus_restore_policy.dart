import 'package:flutter/widgets.dart';

class MoviFocusRestorePolicy {
  const MoviFocusRestorePolicy({
    required this.initialFocusNode,
    this.fallbackFocusNode,
    this.restoreFocusOnReturn = true,
  });

  final FocusNode initialFocusNode;
  final FocusNode? fallbackFocusNode;
  final bool restoreFocusOnReturn;
}
