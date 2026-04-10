import 'package:flutter/material.dart';

class ProfileDialogFocusBorder extends StatelessWidget {
  const ProfileDialogFocusBorder({
    super.key,
    required this.focusNode,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
  });

  final FocusNode focusNode;
  final Widget child;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(
              color: focusNode.hasFocus ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
          child: child,
        );
      },
    );
  }
}
