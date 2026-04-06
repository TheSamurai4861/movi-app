class FeatureFlags {
  const FeatureFlags({
    this.useRemoteHome = false,
    this.disableHomeHero = false,
    this.enableTelemetry = false,
    this.enableEntryJourneyTelemetryV2 = false,
    this.enableEntryJourneyStateModelV2 = false,
    this.enableEntryJourneyRoutingV2 = false,
    this.enableDownloads = false,
    this.enableNewSearch = false,
    this.allowAuthStubFallback = false,
    this.allowInMemoryStorageFallback = false,
  });

  final bool useRemoteHome;

  /// Désactive complètement le hero de la Home (carrousel + enrichissement TMDB).
  /// Utile pour isoler un crash lié au Hero/TMDB.
  final bool disableHomeHero;
  final bool enableTelemetry;
  final bool enableEntryJourneyTelemetryV2;
  final bool enableEntryJourneyStateModelV2;
  final bool enableEntryJourneyRoutingV2;
  final bool enableDownloads;
  final bool enableNewSearch;

  /// Autorise explicitement le fallback vers [StubAuthRepository] quand
  /// Supabase est configuré mais que le client n'est pas enregistré.
  ///
  /// Doit rester désactivé en exécution normale.
  final bool allowAuthStubFallback;

  /// Autorise explicitement le fallback vers une base SQLite en mémoire quand
  /// l'initialisation de la base persistée échoue.
  ///
  /// Doit rester désactivé en exécution normale.
  final bool allowInMemoryStorageFallback;

  FeatureFlags copyWith({
    bool? useRemoteHome,
    bool? disableHomeHero,
    bool? enableTelemetry,
    bool? enableEntryJourneyTelemetryV2,
    bool? enableEntryJourneyStateModelV2,
    bool? enableEntryJourneyRoutingV2,
    bool? enableDownloads,
    bool? enableNewSearch,
    bool? allowAuthStubFallback,
    bool? allowInMemoryStorageFallback,
  }) {
    return FeatureFlags(
      useRemoteHome: useRemoteHome ?? this.useRemoteHome,
      disableHomeHero: disableHomeHero ?? this.disableHomeHero,
      enableTelemetry: enableTelemetry ?? this.enableTelemetry,
      enableEntryJourneyTelemetryV2:
          enableEntryJourneyTelemetryV2 ?? this.enableEntryJourneyTelemetryV2,
      enableEntryJourneyStateModelV2:
          enableEntryJourneyStateModelV2 ?? this.enableEntryJourneyStateModelV2,
      enableEntryJourneyRoutingV2:
          enableEntryJourneyRoutingV2 ?? this.enableEntryJourneyRoutingV2,
      enableDownloads: enableDownloads ?? this.enableDownloads,
      enableNewSearch: enableNewSearch ?? this.enableNewSearch,
      allowAuthStubFallback:
          allowAuthStubFallback ?? this.allowAuthStubFallback,
      allowInMemoryStorageFallback:
          allowInMemoryStorageFallback ?? this.allowInMemoryStorageFallback,
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
        enableEntryJourneyTelemetryV2 == other.enableEntryJourneyTelemetryV2 &&
        enableEntryJourneyStateModelV2 ==
            other.enableEntryJourneyStateModelV2 &&
        enableEntryJourneyRoutingV2 == other.enableEntryJourneyRoutingV2 &&
        enableDownloads == other.enableDownloads &&
        enableNewSearch == other.enableNewSearch &&
        allowAuthStubFallback == other.allowAuthStubFallback &&
        allowInMemoryStorageFallback == other.allowInMemoryStorageFallback;
  }

  @override
  int get hashCode => Object.hash(
    useRemoteHome,
    disableHomeHero,
    enableTelemetry,
    enableEntryJourneyTelemetryV2,
    enableEntryJourneyStateModelV2,
    enableEntryJourneyRoutingV2,
    enableDownloads,
    enableNewSearch,
    allowAuthStubFallback,
    allowInMemoryStorageFallback,
  );

  @override
  String toString() {
    return 'FeatureFlags('
        'useRemoteHome: $useRemoteHome, '
        'disableHomeHero: $disableHomeHero, '
        'enableTelemetry: $enableTelemetry, '
        'enableEntryJourneyTelemetryV2: $enableEntryJourneyTelemetryV2, '
        'enableEntryJourneyStateModelV2: $enableEntryJourneyStateModelV2, '
        'enableEntryJourneyRoutingV2: $enableEntryJourneyRoutingV2, '
        'enableDownloads: $enableDownloads, '
        'enableNewSearch: $enableNewSearch, '
        'allowAuthStubFallback: $allowAuthStubFallback, '
        'allowInMemoryStorageFallback: $allowInMemoryStorageFallback'
        ')';
  }
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
