import 'package:flutter/widgets.dart';
import 'package:movi/src/core/focus/domain/focus_restore_strategy.dart';

typedef FocusNodeResolver = FocusNode? Function();

class FocusRegionBinding {
  const FocusRegionBinding({
    required this.resolvePrimaryEntryNode,
    this.resolveFallbackEntryNode,
    this.restoreStrategy = FocusRestoreStrategy.restoreLastFocused,
  });

  final FocusNodeResolver resolvePrimaryEntryNode;
  final FocusNodeResolver? resolveFallbackEntryNode;
  final FocusRestoreStrategy restoreStrategy;
}
