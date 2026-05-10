import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const MethodChannel _deviceCapabilitiesChannel = MethodChannel(
  'movi/device_capabilities',
);

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
