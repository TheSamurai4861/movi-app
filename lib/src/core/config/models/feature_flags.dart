class FeatureFlags {
  const FeatureFlags({
    this.useRemoteHome = false,
    this.enableTelemetry = false,
    this.enableDownloads = false,
    this.enableNewSearch = false,
  });

  final bool useRemoteHome;
  final bool enableTelemetry;
  final bool enableDownloads;
  final bool enableNewSearch;

  FeatureFlags copyWith({
    bool? useRemoteHome,
    bool? enableTelemetry,
    bool? enableDownloads,
    bool? enableNewSearch,
  }) {
    return FeatureFlags(
      useRemoteHome: useRemoteHome ?? this.useRemoteHome,
      enableTelemetry: enableTelemetry ?? this.enableTelemetry,
      enableDownloads: enableDownloads ?? this.enableDownloads,
      enableNewSearch: enableNewSearch ?? this.enableNewSearch,
    );
  }
}
