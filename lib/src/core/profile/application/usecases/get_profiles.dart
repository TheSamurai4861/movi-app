import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/domain/repositories/profile_repository.dart';

/// Use case: rÃƒÆ’Ã‚Â©cupÃƒÆ’Ã‚Â©rer les profils de l'utilisateur.
///
/// Clean:
/// - dÃƒÆ’Ã‚Â©pend uniquement du contrat [ProfileRepository]
/// - aucune notion Supabase / Riverpod / UI ici
class GetProfilesUseCase {
  const GetProfilesUseCase(this._repo);

  final ProfileRepository _repo;

  Future<List<Profile>> call({
    String? accountId,
    bool? diagnostics,
  }) {
    return _repo.getProfiles(
      accountId: accountId,
      diagnostics: diagnostics,
    );
  }
}
