import 'package:flutter/foundation.dart';

enum AppPlatform { android, ios, macos, windows, linux, web, fuchsia, unknown }

abstract class PlatformInfo {
  AppPlatform get currentPlatform;
  bool get isReleaseMode;
}

class PlatformSelector implements PlatformInfo {
  const PlatformSelector();

  @override
  AppPlatform get currentPlatform {
    if (kIsWeb) {
      return AppPlatform.web;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AppPlatform.android;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppPlatform.ios;
    }
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      return AppPlatform.macos;
    }
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return AppPlatform.windows;
    }
    if (defaultTargetPlatform == TargetPlatform.linux) {
      return AppPlatform.linux;
    }
    if (defaultTargetPlatform == TargetPlatform.fuchsia) {
      return AppPlatform.fuchsia;
    }

    return AppPlatform.unknown;
  }

  @override
  bool get isReleaseMode => kReleaseMode;
}
