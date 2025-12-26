import 'package:movi/src/core/performance/domain/device_capabilities.dart';

abstract class DeviceCapabilitiesRepository {
  Future<DeviceCapabilities> readCapabilities();
}

