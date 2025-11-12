import 'dart:async';
import 'package:flutter/material.dart';

/// Scrolling text with gradient fade on both sides, used for titles and labels.
class MoviMarqueeText extends StatefulWidget {
  const MoviMarqueeText({
    super.key,
    required this.text,
    required this.style,
    required this.maxWidth,
    this.pause = const Duration(seconds: 1),
    this.speed = 40.0,
  });

  final String text;
  final TextStyle style;
  final double maxWidth;
  final Duration pause;
  final double speed; // px per second

  @override
  State<MoviMarqueeText> createState() => _MoviMarqueeTextState();
}

class _MoviMarqueeTextState extends State<MoviMarqueeText>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  Future<void>? _loop;
  double _textWidth = 0;
  bool _shouldAnimate = false;
  bool _disposed = false;
  bool _gradientVisible = false;
  late final AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateMetrics());
  }

  @override
  void didUpdateWidget(covariant MoviMarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.style != widget.style ||
        oldWidget.maxWidth != widget.maxWidth) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateMetrics());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _loop = null;
    _scrollController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textWidget = Align(
      alignment: Alignment.centerLeft,
      child: Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
        overflow: TextOverflow.visible,
      ),
    );

    return SizedBox(
      height: widget.style.fontSize != null ? widget.style.fontSize! * 1.5 : 24,
      width: widget.maxWidth,
      child: AnimatedBuilder(
        animation: _gradientController,
        builder: (context, child) {
          final strength = _gradientController.value;
          final leftColor = Color.lerp(
            Colors.white,
            Colors.transparent,
            strength,
          )!;
          final rightColor = Color.lerp(
            Colors.white,
            Colors.transparent,
            strength,
          )!;

          return ClipRect(
            child: ShaderMask(
              shaderCallback: (rect) {
                final adjusted = Rect.fromLTWH(
                  rect.left - 1,
                  rect.top,
                  rect.width + 4,
                  rect.height,
                );
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [leftColor, Colors.white, Colors.white, rightColor],
                  stops: const [0.0, 0.08, 0.92, 1.0],
                ).createShader(adjusted);
              },
              blendMode: BlendMode.dstIn,
              child: child,
            ),
          );
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: textWidget,
        ),
      ),
    );
  }

  void _updateMetrics() {
    if (_disposed) return;
    final width = _measureTextWidth(widget.text, widget.style);
    final shouldAnimate = width > widget.maxWidth + 1;

    setState(() {
      _textWidth = width;
      _shouldAnimate = shouldAnimate;
    });

    if (!shouldAnimate) {
      _setGradient(false);
      _resetScroll();
      return;
    }

    _startLoop();
  }

  void _startLoop() {
    if (_disposed || !_shouldAnimate) return;
    if (_loop != null) return;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _setGradient(false);
    _loop = _runLoop().whenComplete(() => _loop = null);
  }

  void _resetScroll() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_disposed || !_scrollController.hasClients) return;
        _scrollController.jumpTo(0);
      });
    }
  }

  Future<void> _runLoop() async {
    while (!_disposed && _shouldAnimate) {
      _setGradient(false);
      await Future.delayed(widget.pause);
      if (_disposed || !_shouldAnimate) break;
      _setGradient(true);
      await _animateTo(_maxExtent());
      if (_disposed || !_shouldAnimate) break;
      await Future.delayed(widget.pause);
      if (_disposed || !_shouldAnimate) break;
      _setGradient(true);
      await _animateTo(0);
    }
    _setGradient(false);
  }

  double _maxExtent() =>
      (_textWidth - widget.maxWidth).clamp(0.0, double.infinity);

  Future<void> _animateTo(double target) async {
    if (!_scrollController.hasClients) return;
    final current = _scrollController.offset;
    final distance = (target - current).abs();
    if (distance < 0.5) {
      _scrollController.jumpTo(target);
      if (target == 0 || target == _maxExtent()) {
        _setGradient(false);
      }
      return;
    }

    final durationMs = (distance / widget.speed * 1000)
        .clamp(300, 6000)
        .toInt();
    try {
      await _scrollController.animateTo(
        target,
        duration: Duration(milliseconds: durationMs),
        curve: Curves.easeInOut,
      );
    } catch (_) {
      // Ignore if controller disposed mid-animation.
    }

    if (target == 0 || target == _maxExtent()) {
      _setGradient(false);
    }
  }

  double _measureTextWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.size.width;
  }

  void _setGradient(bool show) {
    if (_disposed) return;
    if (_gradientVisible == show) return;
    _gradientVisible = show;
    if (show) {
      _gradientController.forward();
    } else {
      _gradientController.reverse();
    }
  }
}
