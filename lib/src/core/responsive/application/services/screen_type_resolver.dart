import 'package:flutter/foundation.dart';
import 'package:movi/src/core/responsive/domain/entities/breakpoints.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/core/responsive/application/services/windows_host_detector.dart';

/// Resolves a [ScreenType] from logical viewport dimensions.
class ScreenTypeResolver {
  ScreenTypeResolver._();

  static final ScreenTypeResolver instance = ScreenTypeResolver._();

  ScreenType resolve(double width, double height, {TargetPlatform? platform}) {
    if (width <= 0 || height <= 0) return ScreenType.mobile;
    final effectivePlatform = platform ?? defaultTargetPlatform;

    if (_isForcedWindowsTv(effectivePlatform)) {
      return ScreenType.tv;
    }

    final shortestSide = width < height ? width : height;
    final longestSide = width > height ? width : height;
    final aspectRatio = longestSide / shortestSide;
    final isTabletBand =
        shortestSide > Breakpoints.mobileMax &&
        shortestSide <= Breakpoints.tabletMaxShortestSide;

    if (isTabletBand) {
      if (_supportsTabletOrientationRule(effectivePlatform)) {
        return width > height ? ScreenType.tv : ScreenType.mobile;
      }
      return ScreenType.desktop;
    }

    // TV detection:
    // - wide aspect ratio,
    // - enough logical size to exclude phones in landscape.
    if (aspectRatio >= Breakpoints.tvAspectRatio &&
        shortestSide >= Breakpoints.tvMinShortestSide &&
        longestSide >= Breakpoints.tvMinLongestSide) {
      return ScreenType.tv;
    }

    if (shortestSide > Breakpoints.tabletMaxShortestSide) {
      return ScreenType.desktop;
    }

    return ScreenType.mobile;
  }

  bool _supportsTabletOrientationRule(TargetPlatform platform) {
    return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  }

  bool _isForcedWindowsTv(TargetPlatform platform) {
    if (platform == TargetPlatform.windows) return true;
    if (!kIsWeb) return false;
    return isWindowsWebHost();
  }
}
