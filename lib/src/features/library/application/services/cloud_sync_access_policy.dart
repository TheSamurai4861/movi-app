import 'package:flutter/foundation.dart';

@immutable
class CloudSyncAccessState {
  const CloudSyncAccessState({
    required this.userWantsAutoSync,
    required this.isAuthenticated,
    required this.hasPremiumEntitlement,
  });

  final bool userWantsAutoSync;
  final bool isAuthenticated;
  final bool hasPremiumEntitlement;

  bool get effectiveCloudSyncEnabled =>
      userWantsAutoSync && isAuthenticated && hasPremiumEntitlement;

  CloudSyncAccessState copyWith({
    bool? userWantsAutoSync,
    bool? isAuthenticated,
    bool? hasPremiumEntitlement,
  }) {
    return CloudSyncAccessState(
      userWantsAutoSync: userWantsAutoSync ?? this.userWantsAutoSync,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      hasPremiumEntitlement:
          hasPremiumEntitlement ?? this.hasPremiumEntitlement,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CloudSyncAccessState &&
            other.userWantsAutoSync == userWantsAutoSync &&
            other.isAuthenticated == isAuthenticated &&
            other.hasPremiumEntitlement == hasPremiumEntitlement;
  }

  @override
  int get hashCode =>
      Object.hash(userWantsAutoSync, isAuthenticated, hasPremiumEntitlement);

  @override
  String toString() {
    return 'CloudSyncAccessState('
        'userWantsAutoSync: $userWantsAutoSync, '
        'isAuthenticated: $isAuthenticated, '
        'hasPremiumEntitlement: $hasPremiumEntitlement, '
        'effectiveCloudSyncEnabled: $effectiveCloudSyncEnabled'
        ')';
  }
}

class CloudSyncAccessPolicy {
  const CloudSyncAccessPolicy();

  CloudSyncAccessState resolve({
    required bool userWantsAutoSync,
    required bool isAuthenticated,
    required bool hasPremiumEntitlement,
  }) {
    return CloudSyncAccessState(
      userWantsAutoSync: userWantsAutoSync,
      isAuthenticated: isAuthenticated,
      hasPremiumEntitlement: hasPremiumEntitlement,
    );
  }

  bool isEnabled({
    required bool userWantsAutoSync,
    required bool isAuthenticated,
    required bool hasPremiumEntitlement,
  }) {
    return resolve(
      userWantsAutoSync: userWantsAutoSync,
      isAuthenticated: isAuthenticated,
      hasPremiumEntitlement: hasPremiumEntitlement,
    ).effectiveCloudSyncEnabled;
  }
}
