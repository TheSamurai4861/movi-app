import 'package:movi/src/core/performance/domain/device_capabilities.dart';
import 'package:movi/src/core/performance/domain/performance_profile.dart';

class ResolvePerformanceProfile {
  const ResolvePerformanceProfile();

  static const int _gb = 1024 * 1024 * 1024;

  /// Heuristique volontairement simple:
  /// - iOS est considéré "normal" (observé OK dans le projet).
  /// - Android low-resources si RAM détectée <= 4GB ou CPU <= 4.
  PerformanceProfile call(DeviceCapabilities caps) {
    if (caps.platform == DevicePlatform.ios) return PerformanceProfile.normal;
    if (caps.platform != DevicePlatform.android) return PerformanceProfile.normal;

    final total = caps.totalMemoryBytes;
    if (total != null && total > 0 && total <= 4 * _gb) {
      return PerformanceProfile.lowResources;
    }

    if (caps.cpuCores > 0 && caps.cpuCores <= 4) {
      return PerformanceProfile.lowResources;
    }

    return PerformanceProfile.normal;
  }
}
