import 'package:flutter/material.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/presentation/focus_overlay_scope.dart';

/// Focus boundary dedicated to dialogs, sheets and temporary overlays.
///
/// It requests an explicit entry node when mounted, traps focus inside the
/// overlay subtree and restores focus through the shared overlay policy when
/// the overlay is removed.
class MoviOverlayFocusScope extends StatelessWidget {
  const MoviOverlayFocusScope({
    super.key,
    required this.child,
    required this.initialFocusNode,
    this.fallbackFocusNode,
    this.triggerFocusNode,
    this.originRegionId,
    this.overlayRegionId = AppFocusRegionId.dialogPrimary,
    this.fallbackRegionId = AppFocusRegionId.shellSidebar,
    this.debugLabel,
  });

  final Widget child;
  final FocusNode initialFocusNode;
  final FocusNode? fallbackFocusNode;
  final FocusNode? triggerFocusNode;
  final AppFocusRegionId? originRegionId;
  final AppFocusRegionId overlayRegionId;
  final AppFocusRegionId? fallbackRegionId;
  final String? debugLabel;

  @override
  Widget build(BuildContext context) {
    return FocusOverlayScope(
      initialFocusNode: initialFocusNode,
      fallbackFocusNode: fallbackFocusNode,
      triggerFocusNode: triggerFocusNode,
      originRegionId: originRegionId,
      overlayRegionId: overlayRegionId,
      fallbackRegionId: fallbackRegionId,
      debugLabel: debugLabel,
      child: child,
    );
  }
}
