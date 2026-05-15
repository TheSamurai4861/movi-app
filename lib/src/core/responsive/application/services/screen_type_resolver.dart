import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/responsive/domain/entities/breakpoints.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/core/responsive/application/services/windows_host_detector.dart';
import 'package:movi/src/core/state/device_capabilities_provider.dart';

/// Resolves a [ScreenType] from logical viewport dimensions.
///
/// **Layout vs native TV**
/// - [ScreenType.tv] can apply on Windows (`_isForcedWindowsTv`) for a 10-foot UI
///   (shell, focus, grids) without implying a physical television.
/// - [isTelevisionDevice] (Riverpod) is `true` only on native Android TV hosts.
///   Use [ScreenTypeResolutionContext.isTelevisionDevice] for hardware-specific
///   tweaks (compact primary buttons, subtitle section hiding, text scale reset).
///   Do not infer native TV from [ScreenType.tv] alone.
class ScreenTypeResolver {
  ScreenTypeResolver._();

  static final ScreenTypeResolver instance = ScreenTypeResolver._();

  ScreenType resolve(
    double width,
    double height, {
    TargetPlatform? platform,
    required bool isTelevisionDevice,
  }) {
    if (width <= 0 || height <= 0) return ScreenType.mobile;
    final effectivePlatform = platform ?? defaultTargetPlatform;

    if (_isForcedWindowsTv(effectivePlatform)) {
      return ScreenType.tv;
    }

    if (isTelevisionDevice) {
      return ScreenType.tv;
    }

    final shortestSide = width < height ? width : height;
    if (shortestSide > Breakpoints.mobileMax &&
        shortestSide <= Breakpoints.tabletMaxShortestSide) {
      return ScreenType.tablet;
    }

    if (shortestSide > Breakpoints.tabletMaxShortestSide) {
      return ScreenType.desktop;
    }

    return ScreenType.mobile;
  }

  /// Windows (and Windows web) always use the TV layout class for dev / remote UX.
  bool _isForcedWindowsTv(TargetPlatform platform) {
    if (platform == TargetPlatform.windows) return true;
    if (!kIsWeb) return false;
    return isWindowsWebHost();
  }
}

extension ScreenTypeResolutionContext on BuildContext {
  /// Native Android TV host (UIMode), not Windows with a TV layout.
  bool get isTelevisionDevice {
    try {
      return ProviderScope.containerOf(
        this,
        listen: false,
      ).read(isTelevisionDeviceProvider);
    } catch (_) {
      return false;
    }
  }

  /// Alias for [isTelevisionDevice] — prefer this name for native-only tweaks.
  bool get isNativeTelevisionDevice => isTelevisionDevice;

  ScreenType resolveScreenType(
    double width,
    double height, {
    TargetPlatform? platform,
  }) {
    return ScreenTypeResolver.instance.resolve(
      width,
      height,
      platform: platform,
      isTelevisionDevice: isTelevisionDevice,
    );
  }
}
