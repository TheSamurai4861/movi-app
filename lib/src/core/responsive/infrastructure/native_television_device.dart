import 'package:movi/src/core/responsive/infrastructure/native_television_device_stub.dart'
    if (dart.library.io) 'package:movi/src/core/responsive/infrastructure/native_television_device_io.dart';

abstract final class NativeTelevisionDevice {
  static Future<bool> detect() => detectTelevisionDevice();
}
