class AppLaunchCriteria {
  const AppLaunchCriteria({
    required this.hasSession,
    required this.hasSelectedProfile,
    required this.hasSelectedSource,
  });

  final bool hasSession;
  final bool hasSelectedProfile;
  final bool hasSelectedSource;

  bool get isHomeReady =>
      hasSession && hasSelectedProfile && hasSelectedSource;

  static const AppLaunchCriteria empty = AppLaunchCriteria(
    hasSession: false,
    hasSelectedProfile: false,
    hasSelectedSource: false,
  );

  factory AppLaunchCriteria.fromIds({
    required String? accountId,
    required String? selectedProfileId,
    required String? selectedSourceId,
  }) {
    return AppLaunchCriteria(
      hasSession: accountId != null && accountId.trim().isNotEmpty,
      hasSelectedProfile:
          selectedProfileId != null && selectedProfileId.trim().isNotEmpty,
      hasSelectedSource:
          selectedSourceId != null && selectedSourceId.trim().isNotEmpty,
    );
  }
}
