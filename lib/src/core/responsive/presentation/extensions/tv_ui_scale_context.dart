import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';

class AppTvUiScale extends InheritedWidget {
  const AppTvUiScale({
    super.key,
    required this.tvUiScale,
    required super.child,
  });

  final double tvUiScale;

  static AppTvUiScale? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppTvUiScale>();
  }

  @override
  bool updateShouldNotify(AppTvUiScale oldWidget) {
    return tvUiScale != oldWidget.tvUiScale;
  }
}

/// Applies a normalized UI scale for television layouts.
///
/// Google TV devices can expose smaller logical viewports than desktop hosts.
/// This scale lets widgets adapt non-text dimensions progressively.
class AppTvUiScaleScope extends StatelessWidget {
  const AppTvUiScaleScope({super.key, required this.child});

  static const double _tvScaleMin = 0.85;
  static const double _tvScaleMax = 1.0;
  static const double _tvBaselineShortestSide = 1080.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) {
      return AppTvUiScale(tvUiScale: 1.0, child: child);
    }

    final screenType = context.resolveScreenType(
      mediaQuery.size.width,
      mediaQuery.size.height,
    );
    if (screenType != ScreenType.tv) {
      return AppTvUiScale(tvUiScale: 1.0, child: child);
    }

    final shortestSide = math.min(
      mediaQuery.size.width,
      mediaQuery.size.height,
    );
    final baseScale = shortestSide / _tvBaselineShortestSide;
    final tvUiScale = baseScale.clamp(_tvScaleMin, _tvScaleMax).toDouble();
    return AppTvUiScale(tvUiScale: tvUiScale, child: child);
  }
}

extension AppTvUiScaleContext on BuildContext {
  double get tvUiScale {
    return AppTvUiScale.maybeOf(this)?.tvUiScale ?? 1.0;
  }
}
