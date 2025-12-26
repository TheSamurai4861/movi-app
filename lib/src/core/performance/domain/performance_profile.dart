enum PerformanceProfile { normal, lowResources }

extension PerformanceProfileX on PerformanceProfile {
  bool get isLowResources => this == PerformanceProfile.lowResources;
}

