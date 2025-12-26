import 'package:equatable/equatable.dart';

enum DevicePlatform { android, ios, other }

class DeviceCapabilities extends Equatable {
  const DeviceCapabilities({
    required this.platform,
    required this.cpuCores,
    this.totalMemoryBytes,
  });

  final DevicePlatform platform;
  final int cpuCores;

  /// Total RAM when detectable (best-effort).
  ///
  /// On Android this is typically from `/proc/meminfo` (MemTotal).
  final int? totalMemoryBytes;

  @override
  List<Object?> get props => [platform, cpuCores, totalMemoryBytes];
}

