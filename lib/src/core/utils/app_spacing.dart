import 'package:flutter/widgets.dart';

/// Centralised spacing scale following a multiple-of-4 rule.
class AppSpacing {
  const AppSpacing._();

  static const double zero = 0;
  static const double xxxs = 4;
  static const double xxs = 8;
  static const double xs = 12;
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  /// Standard horizontal padding used across most screens.
  static const EdgeInsets page = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: lg,
  );

  /// Standard spacing for sections on a page.
  static const double sectionGap = 32;

  /// Returns a SizedBox with the given height.
  static SizedBox vertical(double value) => SizedBox(height: value);

  /// Returns a SizedBox with the given width.
  static SizedBox horizontal(double value) => SizedBox(width: value);
}
