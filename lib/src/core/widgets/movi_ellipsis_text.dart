import 'package:flutter/material.dart';

/// Single-line label constrained by [maxWidth], with ellipsis when text is too long.
class MoviEllipsisText extends StatelessWidget {
  const MoviEllipsisText({
    super.key,
    required this.text,
    required this.style,
    required this.maxWidth,
    this.textAlign = TextAlign.center,
  });

  final String text;
  final TextStyle style;
  final double maxWidth;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: maxWidth,
      child: Text(
        text,
        style: style,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
      ),
    );
  }
}
