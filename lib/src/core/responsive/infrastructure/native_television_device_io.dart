import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const MethodChannel _deviceCapabilitiesChannel = MethodChannel(
  'movi/device_capabilities',
);

/// Reports Android UIMode TV only. Windows/macOS/iOS never return `true` here,
/// even when the app uses [ScreenType.tv] for a 10-foot layout on desktop.
Future<bool> detectTelevisionDevice() async {
  if (defaultTargetPlatform != TargetPlatform.android) {
    return false;
  }

  try {
    return await _deviceCapabilitiesChannel.invokeMethod<bool>(
          'isTelevisionDevice',
        ) ??
        false;
  } on MissingPluginException {
    return false;
  } on PlatformException {
    return false;
  }
}
