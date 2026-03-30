import 'package:movi/src/core/auth/domain/repositories/auth_repository.dart';
import 'package:movi/src/core/profile/data/repositories/local_profile_repository.dart';
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/domain/repositories/profile_repository.dart';

class FallbackProfileRepository implements ProfileRepository {
  const FallbackProfileRepository({
    required LocalProfileRepository local,
    required AuthRepository auth,
    ProfileRepository? remote,
  }) : _local = local,
       _auth = auth,
       _remote = remote;

  final LocalProfileRepository _local;
  final AuthRepository _auth;
  final ProfileRepository? _remote;

  @override
  Future<List<Profile>> getProfiles({
    String? accountId,
    bool? diagnostics,
  }) async {
    final localProfiles = await _loadLocalProfiles(accountId: accountId);

    final remoteAccountId = _resolveRemoteAccountId(accountId);
    if (_remote == null || remoteAccountId == null) {
      return localProfiles;
    }

    try {
      final remoteProfiles = await _remote.getProfiles(
        accountId: remoteAccountId,
        diagnostics: diagnostics,
      );
      if (remoteProfiles.isNotEmpty) {
        await _local.upsertProfiles(remoteProfiles);
      }
      return remoteProfiles;
    } catch (_) {
      return localProfiles;
    }
  }

  @override
  Future<Profile> createProfile({
    required String name,
    required int color,
    String? avatarUrl,
    String? accountId,
    bool? diagnostics,
  }) async {
    final remoteAccountId = _resolveRemoteAccountId(accountId);
    if (_remote != null && remoteAccountId != null) {
      try {
        final remoteProfile = await _remote.createProfile(
          name: name,
          color: color,
          avatarUrl: avatarUrl,
          accountId: remoteAccountId,
          diagnostics: diagnostics,
        );
        await _local.upsertProfile(remoteProfile);
        return remoteProfile;
      } catch (_) {
        // Fall back to local-only creation.
      }
    }

    return _local.createProfile(
      name: name,
      color: color,
      avatarUrl: avatarUrl,
      accountId: remoteAccountId ?? LocalProfileRepository.defaultAccountId,
      diagnostics: diagnostics,
    );
  }

  @override
  Future<Profile> updateProfile({
    required String profileId,
    String? name,
    int? color,
    String? avatarUrl,
    bool? isKid,
    Object? pegiLimit = ProfileRepository.noChange,
    bool? diagnostics,
  }) async {
    final localProfile = await _local.updateProfile(
      profileId: profileId,
      name: name,
      color: color,
      avatarUrl: avatarUrl,
      isKid: isKid,
      pegiLimit: pegiLimit,
      diagnostics: diagnostics,
    );

    if (_remote != null && _auth.currentSession != null) {
      try {
        final remoteProfile = await _remote.updateProfile(
          profileId: profileId,
          name: name,
          color: color,
          avatarUrl: avatarUrl,
          isKid: isKid,
          pegiLimit: pegiLimit,
          diagnostics: diagnostics,
        );
        await _local.upsertProfile(remoteProfile);
        return remoteProfile;
      } catch (_) {
        return localProfile;
      }
    }

    return localProfile;
  }

  @override
  Future<void> deleteProfile(String profileId, {bool? diagnostics}) async {
    await _local.deleteProfile(profileId, diagnostics: diagnostics);

    if (_remote != null && _auth.currentSession != null) {
      try {
        await _remote.deleteProfile(profileId, diagnostics: diagnostics);
      } catch (_) {
        // Local deletion remains the source of truth for degraded mode.
      }
    }
  }

  @override
  Future<Profile> getOrCreateDefaultProfile({
    String? accountId,
    bool? diagnostics,
  }) async {
    final profiles = await getProfiles(
      accountId: accountId,
      diagnostics: diagnostics,
    );
    if (profiles.isNotEmpty) return profiles.first;

    return createProfile(
      name: 'Profile',
      color: 0xFF2160AB,
      accountId: accountId,
      diagnostics: diagnostics,
    );
  }

  Future<List<Profile>> _loadLocalProfiles({String? accountId}) async {
    final resolvedAccountId = _resolveRemoteAccountId(accountId);
    if (resolvedAccountId == null) {
      return _local.getProfiles();
    }

    final scoped = await _local.getProfiles(accountId: resolvedAccountId);
    if (resolvedAccountId == LocalProfileRepository.defaultAccountId) {
      return scoped;
    }

    final fallback = await _local.getProfiles(
      accountId: LocalProfileRepository.defaultAccountId,
    );
    return _mergeProfiles(scoped, fallback);
  }

  String? _resolveRemoteAccountId(String? accountId) {
    final explicit = accountId?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;

    final currentUserId = _auth.currentSession?.userId.trim();
    if (currentUserId != null && currentUserId.isNotEmpty) {
      return currentUserId;
    }

    return null;
  }

  List<Profile> _mergeProfiles(
    List<Profile> primary,
    List<Profile> secondary,
  ) {
    final byId = <String, Profile>{};
    for (final profile in secondary) {
      byId[profile.id] = profile;
    }
    for (final profile in primary) {
      byId[profile.id] = profile;
    }

    final merged = byId.values.toList(growable: false)
      ..sort((a, b) {
        final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return aTime.compareTo(bTime);
      });
    return merged;
  }
}
