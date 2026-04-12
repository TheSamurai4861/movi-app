import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  });

  final Widget child;
  final bool isLeadingEdge;
  final bool isTrailingEdge;
  final bool consumeBackwardEdgeKey;
  final bool enableVerticalScroll;
  final double? horizontalAlignment;
  final double verticalAlignment;

  @override
  State<MoviEnsureVisibleOnFocus> createState() =>
      _MoviEnsureVisibleOnFocusState();
}

class _MoviEnsureVisibleOnFocusState extends State<MoviEnsureVisibleOnFocus> {
  static const Curve _scrollCurve = Curves.easeOutCubic;
  static const Duration _scrollDuration = Duration(milliseconds: 120);

  bool _ensureVisibleScheduled = false;

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

  void _ensureVisible() {
    if (!mounted || _ensureVisibleScheduled) return;
    _ensureVisibleScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureVisibleScheduled = false;
      if (!mounted) return;

      final target = context.findRenderObject();
      if (target == null) return;

      final horizontalScrollable = Scrollable.maybeOf(
        context,
        axis: Axis.horizontal,
      );
      if (horizontalScrollable != null) {
        _scrollScrollable(horizontalScrollable, target);
      }

      final verticalScrollable = Scrollable.maybeOf(
        context,
        axis: Axis.vertical,
      );
      if (widget.enableVerticalScroll &&
          verticalScrollable != null &&
          !identical(verticalScrollable, horizontalScrollable)) {
        _scrollScrollable(verticalScrollable, target);
      }
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
          if (hasFocus && !isDisabledByAncestor) {
            _ensureVisible();
          }
        },
        child: widget.child,
      ),
    );
  }
}
