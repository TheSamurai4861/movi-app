import 'package:flutter/material.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/core/responsive/presentation/extensions/responsive_context.dart';
import 'package:movi/src/core/widgets/movi_focus_frame.dart';

class MoviFocusableAction extends StatefulWidget {
  const MoviFocusableAction({
    super.key,
    required this.builder,
    this.onPressed,
    this.onLongPress,
    this.focusNode,
    this.autofocus = false,
    this.enableHover = true,
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
