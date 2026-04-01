class AppLaunchCriteria {
  const AppLaunchCriteria({
    required this.hasSession,
    required this.hasSelectedProfile,
    required this.hasSelectedSource,
    required this.hasIptvCatalogReady,
    required this.hasHomePreloaded,
    required this.hasLibraryReady,
  });

  final bool hasSession;
  final bool hasSelectedProfile;
  final bool hasSelectedSource;
  final bool hasIptvCatalogReady;
  final bool hasHomePreloaded;
  final bool hasLibraryReady;

  bool get isHomeReady =>
      hasSelectedProfile &&
      hasSelectedSource &&
      hasIptvCatalogReady &&
      hasHomePreloaded &&
      hasLibraryReady;

  static const AppLaunchCriteria empty = AppLaunchCriteria(
    hasSession: false,
    hasSelectedProfile: false,
    hasSelectedSource: false,
    hasIptvCatalogReady: false,
    hasHomePreloaded: false,
    hasLibraryReady: false,
  );

  factory AppLaunchCriteria.fromLaunchContext({
    required String? accountId,
    required String? selectedProfileId,
    required String? selectedSourceId,
    bool hasIptvCatalogReady = false,
    bool hasHomePreloaded = false,
    bool hasLibraryReady = false,
  }) {
    return AppLaunchCriteria(
      hasSession: accountId != null && accountId.trim().isNotEmpty,
      hasSelectedProfile:
          selectedProfileId != null && selectedProfileId.trim().isNotEmpty,
      hasSelectedSource:
          selectedSourceId != null && selectedSourceId.trim().isNotEmpty,
      hasIptvCatalogReady: hasIptvCatalogReady,
      hasHomePreloaded: hasHomePreloaded,
      hasLibraryReady: hasLibraryReady,
    );
  }
}
