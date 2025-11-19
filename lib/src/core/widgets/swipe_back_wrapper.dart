import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Widget wrapper qui permet de revenir en arrière avec un swipe de gauche à droite
class SwipeBackWrapper extends StatefulWidget {
  const SwipeBackWrapper({super.key, required this.child});

  final Widget child;

  @override
  State<SwipeBackWrapper> createState() => _SwipeBackWrapperState();
}

class _SwipeBackWrapperState extends State<SwipeBackWrapper> {
  bool _swipeActive = false;
  double _swipeStartX = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (details) {
        _swipeActive = true;
        _swipeStartX = details.globalPosition.dx;
      },
      onHorizontalDragUpdate: (details) {
        if (!_swipeActive) return;
        final moved = details.globalPosition.dx - _swipeStartX;
        // Si le swipe dépasse 80 pixels vers la droite, revenir en arrière
        if (moved > 80) {
          _swipeActive = false;
          if (mounted && context.canPop()) {
            context.pop();
          }
        }
      },
      onHorizontalDragEnd: (_) {
        _swipeActive = false;
      },
      child: widget.child,
    );
  }
}
