import 'package:movi/src/core/profile/domain/entities/profile.dart';

/// Contrat mÃƒÆ’Ã‚Â©tier pour les profils.
/// Les implÃƒÆ’Ã‚Â©mentations (Supabase, SQLite, fake, etc.) vivent en data/.
abstract interface class ProfileRepository {
  static const Object noChange = Object();

  Future<List<Profile>> getProfiles({
    String? accountId,
    bool? diagnostics,
  });

  Future<Profile> createProfile({
    required String name,
    required int color,
    String? avatarUrl,
    String? accountId,
    bool? diagnostics,
  });

  Future<Profile> updateProfile({
    required String profileId,
    String? name,
    int? color,
    String? avatarUrl,
    bool? isKid,
    Object? pegiLimit = noChange,
    bool? diagnostics,
  });

  Future<void> deleteProfile(
    String profileId, {
    bool? diagnostics,
  });

  Future<Profile> getOrCreateDefaultProfile({
    String? accountId,
    bool? diagnostics,
  });
}
