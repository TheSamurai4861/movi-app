import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/core/responsive/presentation/extensions/tv_ui_scale_context.dart';

/// Calcule des dimensions de decode raster pour cartes / posters en liste.
class ImageDecodeSize {
  const ImageDecodeSize._();

  static const int _standardMaxEdge = 1280;
  static const int _tvMaxEdge = 960;
  static const int _minEdge = 120;

  static int? decodePixelForLogical(
    BuildContext context,
    double logicalSize, {
    double scaleFactor = 2,
    int? maxEdge,
  }) {
    if (!logicalSize.isFinite || logicalSize <= 0) {
      return null;
    }

    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    final uiScale = context.tvUiScale;
    final resolvedMax = maxEdge ?? _maxEdgeForContext(context);
    final px = (logicalSize * uiScale * dpr * scaleFactor).round();
    return math.max(_minEdge, math.min(resolvedMax, px));
  }

  static ({int? width, int? height}) decodeSizeForCard(
    BuildContext context,
    double width,
    double height, {
    double scaleFactor = 2,
  }) {
    return (
      width: decodePixelForLogical(
        context,
        width,
        scaleFactor: scaleFactor,
      ),
      height: decodePixelForLogical(
        context,
        height,
        scaleFactor: scaleFactor,
      ),
    );
  }

  static int _maxEdgeForContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenType = context.resolveScreenType(size.width, size.height);
    if (screenType == ScreenType.tv) {
      return _tvMaxEdge;
    }
    return _standardMaxEdge;
  }
}
