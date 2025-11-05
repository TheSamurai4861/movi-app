import 'package:flutter/material.dart';

import '../di/injector.dart';
import 'app_spacing.dart';
import 'logger.dart';

extension MoviContext on BuildContext {
  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => theme.textTheme;

  ColorScheme get colorScheme => theme.colorScheme;

  AppLogger get logger => sl<AppLogger>();

  /// Provides consistency for page padding.
  EdgeInsets get pagePadding => AppSpacing.page;

  MediaQueryData get mediaQuery => MediaQuery.of(this);

  Size get screenSize => mediaQuery.size;
}
