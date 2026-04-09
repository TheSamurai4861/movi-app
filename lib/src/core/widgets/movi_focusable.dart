import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movi/src/core/responsive/presentation/extensions/responsive_context.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';

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

class MoviInteractiveState {
  const MoviInteractiveState({
    required this.focused,
    required this.hovered,
    required this.pressed,
  });

  final bool focused;
  final bool hovered;
  final bool pressed;
}

class MoviFocusFrame extends StatelessWidget {
  const MoviFocusFrame({
    super.key,
    required this.child,
    this.scale = 1,
    this.padding = EdgeInsets.zero,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
    this.boxShadow,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 180),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final double scale;
  final EdgeInsetsGeometry padding;
  final BoxShape shape;
  final BorderRadiusGeometry? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;
  final AlignmentGeometry alignment;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;
    final effectiveBorderRadius = shape == BoxShape.circle ? null : radius;
    final hasDecoration =
        backgroundColor != null ||
        (borderColor != null && borderWidth > 0) ||
        (boxShadow != null && boxShadow!.isNotEmpty);

    return AnimatedScale(
      scale: scale,
      duration: duration,
      curve: curve,
      alignment: Alignment.center,
      child: AnimatedContainer(
        duration: duration,
        curve: curve,
        alignment: alignment,
        padding: padding,
        decoration: hasDecoration
            ? BoxDecoration(
                color: backgroundColor,
                shape: shape,
                borderRadius: effectiveBorderRadius,
                border: borderColor != null && borderWidth > 0
                    ? Border.all(color: borderColor!, width: borderWidth)
                    : null,
                boxShadow: boxShadow,
              )
            : null,
        child: child,
      ),
    );
  }
}

typedef MoviFocusableBuilder =
    Widget Function(BuildContext context, MoviInteractiveState state);

class MoviFocusableAction extends StatefulWidget {
  const MoviFocusableAction({
    super.key,
    required this.builder,
    this.onPressed,
    this.onLongPress,
    this.focusNode,
    this.autofocus = false,
    this.enableHover = true,
    this.ensureVisibleOnFocus = true,
    this.ensureVisibleVerticalAlignment,
    this.behavior = HitTestBehavior.opaque,
    this.semanticLabel,
    this.button = true,
    this.toggled,
    this.enabled,
    this.mouseCursor,
  });

  final MoviFocusableBuilder builder;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enableHover;
  final bool ensureVisibleOnFocus;
  final double? ensureVisibleVerticalAlignment;
  final HitTestBehavior behavior;
  final String? semanticLabel;
  final bool button;
  final bool? toggled;
  final bool? enabled;
  final MouseCursor? mouseCursor;

  @override
  State<MoviFocusableAction> createState() => _MoviFocusableActionState();
}

class _MoviFocusableActionState extends State<MoviFocusableAction> {
  bool _focused = false;
  bool _hovered = false;
  bool _pressed = false;

  bool get _enabled => widget.enabled ?? widget.onPressed != null;

  void _ensureVisible() {
    if (!mounted) return;
    if (_MoviEnsureVisibleBoundary.shouldDisableDescendantEnsureVisible(
      context,
    )) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final alignment = widget.ensureVisibleVerticalAlignment;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: alignment ?? 0,
        alignmentPolicy: alignment == null
            ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
            : ScrollPositionAlignmentPolicy.explicit,
      );
    });
  }

  bool _isFocusEnabled(BuildContext context) {
    // `ResponsiveContext` requires `ResponsiveLayout` in the tree. Some widget
    // trees (ex: tests, overlays) may not provide it, so we fall back to
    // `ScreenTypeResolver` based on MediaQuery.
    try {
      return context.isDesktop || context.isTv;
    } catch (_) {
      final mq = MediaQuery.maybeOf(context);
      if (mq == null) return false;
      final type = ScreenTypeResolver.instance.resolve(
        mq.size.width,
        mq.size.height == 0 ? 1 : mq.size.height,
      );
      return type == ScreenType.desktop || type == ScreenType.tv;
    }
  }

  @override
  Widget build(BuildContext context) {
    // On désactive la logique focus (TV/desktop) sur mobile/tablette.
    final focusEnabled = _isFocusEnabled(context);
    final state = MoviInteractiveState(
      focused: focusEnabled ? _focused : false,
      hovered: widget.enableHover ? _hovered : false,
      pressed: _pressed,
    );

    Widget child = FocusableActionDetector(
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      enabled: _enabled && focusEnabled,
      mouseCursor:
          widget.mouseCursor ??
          (widget.enableHover ? SystemMouseCursors.click : MouseCursor.defer),
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (_enabled) {
              widget.onPressed?.call();
            }
            return null;
          },
        ),
      },
      onShowFocusHighlight: (value) {
        if (!focusEnabled) return;
        if (_focused == value) return;
        setState(() => _focused = value);
        if (value && widget.ensureVisibleOnFocus) {
          _ensureVisible();
        }
      },
      onShowHoverHighlight: (value) {
        if (_hovered == value) return;
        setState(() => _hovered = value);
      },
      child: GestureDetector(
        behavior: widget.behavior,
        onTap: _enabled ? widget.onPressed : null,
        onLongPress: _enabled ? widget.onLongPress : null,
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
        child: widget.builder(context, state),
      ),
    );

    child = Semantics(
      button: widget.button,
      enabled: _enabled,
      toggled: widget.toggled,
      label: widget.semanticLabel,
      child: child,
    );

    return Align(
      alignment: Alignment.center,
      widthFactor: 1,
      heightFactor: 1,
      child: child,
    );
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

  void _scrollScrollable(ScrollableState scrollable, RenderObject target) {
    final axis = axisDirectionToAxis(scrollable.axisDirection);
    final position = scrollable.position;

    if (axis == Axis.horizontal) {
      if (widget.isLeadingEdge || widget.isTrailingEdge) {
        final targetOffset = widget.isLeadingEdge
            ? position.minScrollExtent
            : position.maxScrollExtent;
        if (targetOffset != position.pixels) {
          try {
            // Avoid long-lived driven scroll activity during subtree transitions.
            position.jumpTo(targetOffset);
          } catch (_) {
            // Best effort: focus can move while the scrollable is detaching.
          }
        }
        return;
      }

      try {
        final horizontalAlignment = widget.horizontalAlignment;
        position.ensureVisible(
          target,
          duration: Duration.zero,
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
        duration: Duration.zero,
        curve: _scrollCurve,
        alignment: widget.verticalAlignment,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    } catch (_) {
      // Best effort: ignore transient detach races.
    }
  }

  void _ensureVisible() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final blocksBackward = isRtl ? widget.isTrailingEdge : widget.isLeadingEdge;
    final blocksForward = isRtl ? widget.isLeadingEdge : widget.isTrailingEdge;

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
          if (hasFocus) {
            _ensureVisible();
          }
        },
        child: widget.child,
      ),
    );
  }
}
