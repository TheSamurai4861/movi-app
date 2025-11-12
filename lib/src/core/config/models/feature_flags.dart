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

  HomeFlags get home => HomeFlags(useRemoteHome);
  TelemetryFlags get telemetry => TelemetryFlags(enableTelemetry);
  DownloadFlags get downloads => DownloadFlags(enableDownloads);
  SearchFlags get search => SearchFlags(enableNewSearch);
}

class HomeFlags {
  const HomeFlags(this.useRemoteHome);
  final bool useRemoteHome;
}

class TelemetryFlags {
  const TelemetryFlags(this.enableTelemetry);
  final bool enableTelemetry;
}

class DownloadFlags {
  const DownloadFlags(this.enableDownloads);
  final bool enableDownloads;
}

class SearchFlags {
  const SearchFlags(this.enableNewSearch);
  final bool enableNewSearch;
}
