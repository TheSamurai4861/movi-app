import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/domain/repositories/profile_repository.dart';

/// Use case: mettre ÃƒÆ’Ã‚Â  jour un profil (rename / couleur / avatar).
class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repo);

  final ProfileRepository _repo;

  Future<Profile> call({
    required String profileId,
    String? name,
    int? color,
    String? avatarUrl,
    bool? isKid,
    Object? pegiLimit = ProfileRepository.noChange,
    bool? diagnostics,
  }) {
    return _repo.updateProfile(
      profileId: profileId,
      name: name,
      color: color,
      avatarUrl: avatarUrl,
      isKid: isKid,
      pegiLimit: pegiLimit,
      diagnostics: diagnostics,
    );
  }
}
