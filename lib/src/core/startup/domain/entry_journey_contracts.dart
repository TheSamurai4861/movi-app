enum SessionContractStatus { unknown, authenticated, unauthenticated }

final class SessionContractSnapshot {
  const SessionContractSnapshot({
    required this.status,
    this.userId,
    this.reasonCode = 'session_unknown',
  });

  final SessionContractStatus status;
  final String? userId;
  final String reasonCode;

  bool get hasSession => userId != null && userId!.trim().isNotEmpty;
  bool get isAuthenticated => status == SessionContractStatus.authenticated;

  static const unknown = SessionContractSnapshot(
    status: SessionContractStatus.unknown,
  );
}

final class ProfilesContractSnapshot {
  const ProfilesContractSnapshot({
    required this.count,
    required this.hasValidSelection,
    this.selectedProfileId,
    this.reasonCode = 'profiles_unknown',
  });

  final int count;
  final bool hasValidSelection;
  final String? selectedProfileId;
  final String reasonCode;

  bool get requiresProfileSelection => count <= 0 || !hasValidSelection;
}

final class SourcesContractSnapshot {
  const SourcesContractSnapshot({
    required this.localCount,
    required this.remoteCount,
    required this.hasValidSelection,
    required this.requiresManualSelection,
    this.selectedSourceId,
    this.reasonCode = 'sources_unknown',
  });

  final int localCount;
  final int remoteCount;
  final bool hasValidSelection;
  final bool requiresManualSelection;
  final String? selectedSourceId;
  final String reasonCode;

  int get totalCount => localCount > 0 ? localCount : remoteCount;

  bool get requiresSourceSelection =>
      totalCount <= 0 || requiresManualSelection || !hasValidSelection;
}

abstract interface class SessionAuthContract {
  Future<SessionContractSnapshot> read();
}

abstract interface class ProfilesContract {
  Future<ProfilesContractSnapshot> read();
}

abstract interface class SourcesContract {
  Future<SourcesContractSnapshot> read();
}
