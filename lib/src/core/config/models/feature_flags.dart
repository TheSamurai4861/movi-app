class FeatureFlags {
  const FeatureFlags({
    this.useRemoteHome = false,
    this.disableHomeHero = false,
    this.enableTelemetry = false,
    this.enableDownloads = false,
    this.enableNewSearch = false,
  });

  final bool useRemoteHome;

  /// Désactive complètement le hero de la Home (carrousel + enrichissement TMDB).
  /// Utile pour isoler un crash lié au Hero/TMDB.
  final bool disableHomeHero;
  final bool enableTelemetry;
  final bool enableDownloads;
  final bool enableNewSearch;

  FeatureFlags copyWith({
    bool? useRemoteHome,
    bool? disableHomeHero,
    bool? enableTelemetry,
    bool? enableDownloads,
    bool? enableNewSearch,
  }) {
    return FeatureFlags(
      useRemoteHome: useRemoteHome ?? this.useRemoteHome,
      disableHomeHero: disableHomeHero ?? this.disableHomeHero,
      enableTelemetry: enableTelemetry ?? this.enableTelemetry,
      enableDownloads: enableDownloads ?? this.enableDownloads,
      enableNewSearch: enableNewSearch ?? this.enableNewSearch,
    );
  }

  HomeFlags get home => HomeFlags(useRemoteHome, disableHomeHero);
  TelemetryFlags get telemetry => TelemetryFlags(enableTelemetry);
  DownloadFlags get downloads => DownloadFlags(enableDownloads);
  SearchFlags get search => SearchFlags(enableNewSearch);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FeatureFlags) return false;
    return useRemoteHome == other.useRemoteHome &&
        disableHomeHero == other.disableHomeHero &&
        enableTelemetry == other.enableTelemetry &&
        enableDownloads == other.enableDownloads &&
        enableNewSearch == other.enableNewSearch;
  }

  @override
  int get hashCode => Object.hash(
    useRemoteHome,
    disableHomeHero,
    enableTelemetry,
    enableDownloads,
    enableNewSearch,
  );
}

class HomeFlags {
  const HomeFlags(this.useRemoteHome, this.disableHero);
  final bool useRemoteHome;
  final bool disableHero;
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
