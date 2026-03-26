import 'package:flutter/material.dart';

class ModalContentWidth extends StatelessWidget {
  const ModalContentWidth({
    super.key,
    required this.child,
    required this.maxWidth,
    this.maxHeight,
  });

  final Widget child;
  final double maxWidth;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: maxHeight ?? size.height,
      ),
      child: child,
    );
  }
}
