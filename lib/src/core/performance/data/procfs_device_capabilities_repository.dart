import 'dart:io';

import 'package:movi/src/core/performance/domain/device_capabilities.dart';
import 'package:movi/src/core/performance/domain/device_capabilities_repository.dart';

class ProcfsDeviceCapabilitiesRepository implements DeviceCapabilitiesRepository {
  const ProcfsDeviceCapabilitiesRepository();

  @override
  Future<DeviceCapabilities> readCapabilities() async {
    final platform = _detectPlatform();
    final cpuCores = _safeCpuCores();
    final totalMemoryBytes = await _readTotalMemoryBytes(platform);
    return DeviceCapabilities(
      platform: platform,
      cpuCores: cpuCores,
      totalMemoryBytes: totalMemoryBytes,
    );
  }

  DevicePlatform _detectPlatform() {
    if (Platform.isAndroid) return DevicePlatform.android;
    if (Platform.isIOS) return DevicePlatform.ios;
    return DevicePlatform.other;
  }

  int _safeCpuCores() {
    try {
      final cores = Platform.numberOfProcessors;
      return cores > 0 ? cores : 1;
    } catch (_) {
      return 1;
    }
  }

  Future<int?> _readTotalMemoryBytes(DevicePlatform platform) async {
    // Best-effort: `/proc/meminfo` exists on Android/Linux. Not available on iOS.
    if (platform != DevicePlatform.android && platform != DevicePlatform.other) {
      return null;
    }

    try {
      final file = File('/proc/meminfo');
      if (!await file.exists()) return null;

      final lines = await file.readAsLines();
      for (final line in lines) {
        final trimmed = line.trimLeft();
        if (!trimmed.startsWith('MemTotal:')) continue;
        final parts = trimmed.split(RegExp(r'\s+'));
        // Example: ["MemTotal:", "3712348", "kB"]
        if (parts.length < 2) return null;
        final kb = int.tryParse(parts[1]);
        if (kb == null || kb <= 0) return null;
        return kb * 1024;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
