import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Vertical scroll behavior when a descendant receives focus.
enum MoviVerticalRevealPolicy {
  /// Places the focused widget at [MoviEnsureVisibleOnFocus.verticalAlignment].
  anchor,

  /// Scrolls only enough to bring the widget into view (no re-anchor).
  minimal,
}

class _MoviEnsureVisibleBoundary extends InheritedWidget {
  const _MoviEnsureVisibleBoundary({
    required super.child,
    this.disableDescendantEnsureVisible = false,
  });

  final bool disableDescendantEnsureVisible;

  static bool shouldDisableDescendantEnsureVisible(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_MoviEnsureVisibleBoundary>();
    return scope?.disableDescendantEnsureVisible ?? false;
  }

  @override
  bool updateShouldNotify(_MoviEnsureVisibleBoundary oldWidget) {
    return disableDescendantEnsureVisible !=
        oldWidget.disableDescendantEnsureVisible;
  }
}

/// Overrides vertical reveal policy for descendant [MoviEnsureVisibleOnFocus].
class MoviFocusRevealScope extends InheritedWidget {
  const MoviFocusRevealScope({
    super.key,
    required this.policy,
    this.deferLayoutFrames = 0,
    required super.child,
  });

  final MoviVerticalRevealPolicy policy;
  final int deferLayoutFrames;

  static MoviFocusRevealScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MoviFocusRevealScope>();
  }

  static MoviVerticalRevealPolicy policyOf(BuildContext context) {
    return maybeOf(context)?.policy ?? MoviVerticalRevealPolicy.anchor;
  }

  static int deferLayoutFramesOf(BuildContext context) {
    return maybeOf(context)?.deferLayoutFrames ?? 0;
  }

  @override
  bool updateShouldNotify(MoviFocusRevealScope oldWidget) {
    return policy != oldWidget.policy ||
        deferLayoutFrames != oldWidget.deferLayoutFrames;
  }
}

class MoviVerticalEnsureVisibleTarget extends InheritedWidget {
  const MoviVerticalEnsureVisibleTarget({
    super.key,
    required this.targetContext,
    required super.child,
  });

  final BuildContext targetContext;

  static BuildContext? maybeOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<MoviVerticalEnsureVisibleTarget>();
    return scope?.targetContext;
  }

  @override
  bool updateShouldNotify(MoviVerticalEnsureVisibleTarget oldWidget) {
    return targetContext != oldWidget.targetContext;
  }
}

class MoviEnsureVisibleOnFocus extends StatefulWidget {
  const MoviEnsureVisibleOnFocus({
    super.key,
    required this.child,
    this.isLeadingEdge = false,
    this.isTrailingEdge = false,
    this.consumeBackwardEdgeKey = false,
    this.enableVerticalScroll = true,
    this.horizontalAlignment,
    this.verticalAlignment = 0.5,
    this.verticalRevealPolicy,
  });

  final Widget child;
  final bool isLeadingEdge;
  final bool isTrailingEdge;
  final bool consumeBackwardEdgeKey;
  final bool enableVerticalScroll;
  final double? horizontalAlignment;
  final double verticalAlignment;
  final MoviVerticalRevealPolicy? verticalRevealPolicy;

  @override
  State<MoviEnsureVisibleOnFocus> createState() =>
      _MoviEnsureVisibleOnFocusState();
}

class _MoviEnsureVisibleOnFocusState extends State<MoviEnsureVisibleOnFocus> {
  static const Curve _scrollCurve = Curves.easeOutCubic;
  static const Duration _scrollDuration = Duration(milliseconds: 120);
  static const double _visibilityMargin = 24;

  bool _ensureVisibleScheduled = false;
  bool _subtreeHadFocus = false;

  MoviVerticalRevealPolicy get _resolvedVerticalRevealPolicy {
    return widget.verticalRevealPolicy ??
        MoviFocusRevealScope.policyOf(context);
  }

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_handleFocusManagerChanged);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_handleFocusManagerChanged);
    super.dispose();
  }

  bool _isPrimaryFocusInsideSubtree() {
    final primary = FocusManager.instance.primaryFocus;
    if (primary == null || !primary.hasFocus) return false;

    final scopeRenderObject = context.findRenderObject();
    final focusedRenderObject = primary.context?.findRenderObject();
    if (scopeRenderObject == null || focusedRenderObject == null) {
      return false;
    }

    RenderObject? current = focusedRenderObject;
    while (current != null) {
      if (identical(current, scopeRenderObject)) {
        return true;
      }
      current = current.parent;
    }
    return false;
  }

  void _handleFocusManagerChanged() {
    if (!mounted) return;
    if (_MoviEnsureVisibleBoundary.shouldDisableDescendantEnsureVisible(
      context,
    )) {
      return;
    }

    final hasSubtreeFocus = _isPrimaryFocusInsideSubtree();
    if (hasSubtreeFocus && !_subtreeHadFocus) {
      final deferFrames = _resolvedVerticalRevealPolicy ==
              MoviVerticalRevealPolicy.minimal
          ? MoviFocusRevealScope.deferLayoutFramesOf(context)
          : 0;
      _ensureVisible(remainingDeferFrames: deferFrames);
    }
    _subtreeHadFocus = hasSubtreeFocus;
  }

  ScrollableState? _resolveScrollableForAxis(Axis axis) {
    final candidates = <ScrollableState>[];
    context.visitAncestorElements((element) {
      if (element is StatefulElement && element.state is ScrollableState) {
        final scrollable = element.state as ScrollableState;
        if (axisDirectionToAxis(scrollable.axisDirection) == axis) {
          candidates.add(scrollable);
        }
      }
      return true;
    });
    if (candidates.isEmpty) return null;

    if (axis == Axis.vertical) {
      ScrollableState? selected;
      for (final candidate in candidates) {
        final position = candidate.position;
        if (position.hasContentDimensions && position.maxScrollExtent > 0) {
          selected = candidate;
        }
      }
      return selected ?? candidates.last;
    }
    return candidates.first;
  }

  bool _needsVerticalScrollAdjustment(
    ScrollPosition position,
    RenderObject target,
    double alignment,
  ) {
    final viewport = RenderAbstractViewport.maybeOf(target);
    if (viewport == null) return true;

    final reveal = viewport.getOffsetToReveal(target, alignment);
    final desiredOffset = reveal.offset.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    return (desiredOffset - position.pixels).abs() > _visibilityMargin;
  }

  void _scrollVerticalMinimal(ScrollPosition position, RenderObject target) {
    // Use keepVisible policies so Flutter only scrolls when needed. Avoid
    // getOffsetToReveal visibility checks: they can return 0 for off-screen
    // descendants inside a ListView and skip required scrolling.
    try {
      position.ensureVisible(
        target,
        duration: _scrollDuration,
        curve: _scrollCurve,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
      position.ensureVisible(
        target,
        duration: _scrollDuration,
        curve: _scrollCurve,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    } catch (_) {
      // Best effort: ignore transient detach races.
    }
  }

  void _scrollScrollable(ScrollableState scrollable, RenderObject target) {
    final axis = axisDirectionToAxis(scrollable.axisDirection);
    final position = scrollable.position;

    if (axis == Axis.horizontal) {
      final horizontalAlignment =
          widget.horizontalAlignment ??
          (widget.isLeadingEdge
              ? 0.0
              : widget.isTrailingEdge
              ? 1.0
              : null);

      try {
        position.ensureVisible(
          target,
          duration: _scrollDuration,
          curve: _scrollCurve,
          alignment: horizontalAlignment ?? 0,
          alignmentPolicy: horizontalAlignment == null
              ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
              : ScrollPositionAlignmentPolicy.explicit,
        );
      } catch (_) {
        // Best effort: ignore transient detach races.
      }
      return;
    }

    final verticalTargetContext = MoviVerticalEnsureVisibleTarget.maybeOf(
      context,
    );
    final verticalTarget = verticalTargetContext?.findRenderObject() ?? target;

    if (_resolvedVerticalRevealPolicy == MoviVerticalRevealPolicy.minimal) {
      _scrollVerticalMinimal(position, verticalTarget);
      return;
    }

    if (!_needsVerticalScrollAdjustment(
      position,
      verticalTarget,
      widget.verticalAlignment,
    )) {
      return;
    }

    try {
      position.ensureVisible(
        verticalTarget,
        duration: _scrollDuration,
        curve: _scrollCurve,
        alignment: widget.verticalAlignment,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    } catch (_) {
      // Best effort: ignore transient detach races.
    }
  }

  void _runEnsureVisible() {
    if (!mounted) return;

    final target = context.findRenderObject();
    if (target == null) return;

    final horizontalScrollable = _resolveScrollableForAxis(Axis.horizontal);
    if (horizontalScrollable != null) {
      _scrollScrollable(horizontalScrollable, target);
    }

    final verticalScrollable = _resolveScrollableForAxis(Axis.vertical);
    if (widget.enableVerticalScroll &&
        verticalScrollable != null &&
        !identical(verticalScrollable, horizontalScrollable)) {
      _scrollScrollable(verticalScrollable, target);
    }
  }

  void _ensureVisible({int remainingDeferFrames = 0}) {
    if (!mounted || _ensureVisibleScheduled) return;
    _ensureVisibleScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureVisibleScheduled = false;
      if (!mounted) return;

      if (remainingDeferFrames > 0) {
        _ensureVisible(remainingDeferFrames: remainingDeferFrames - 1);
        return;
      }

      _runEnsureVisible();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final blocksBackward = isRtl ? widget.isTrailingEdge : widget.isLeadingEdge;
    final blocksForward = isRtl ? widget.isLeadingEdge : widget.isTrailingEdge;
    final isDisabledByAncestor =
        _MoviEnsureVisibleBoundary.shouldDisableDescendantEnsureVisible(
          context,
        );

    return _MoviEnsureVisibleBoundary(
      disableDescendantEnsureVisible: true,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;

          if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
              blocksBackward) {
            return widget.consumeBackwardEdgeKey
                ? KeyEventResult.handled
                : KeyEventResult.ignored;
          }

          if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
              blocksForward) {
            return KeyEventResult.handled;
          }

          return KeyEventResult.ignored;
        },
        onFocusChange: (hasFocus) {
          if (!hasFocus) {
            _subtreeHadFocus = false;
            return;
          }
          if (!isDisabledByAncestor) {
            final deferFrames = _resolvedVerticalRevealPolicy ==
                    MoviVerticalRevealPolicy.minimal
                ? MoviFocusRevealScope.deferLayoutFramesOf(context)
                : 0;
            _ensureVisible(remainingDeferFrames: deferFrames);
          }
        },
        child: widget.child,
      ),
    );
  }
}
