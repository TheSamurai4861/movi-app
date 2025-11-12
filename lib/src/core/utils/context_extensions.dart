import 'package:flutter/material.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/logging/logger.dart';

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
