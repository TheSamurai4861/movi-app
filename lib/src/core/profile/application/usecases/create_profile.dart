import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/domain/repositories/profile_repository.dart';

/// Use case: crÃƒÆ’Ã‚Â©er un profil.
class CreateProfileUseCase {
  const CreateProfileUseCase(this._repo);

  final ProfileRepository _repo;

  Future<Profile> call({
    required String name,
    required int color,
    String? avatarUrl,
    String? accountId,
    bool? diagnostics,
  }) {
    return _repo.createProfile(
      name: name,
      color: color,
      avatarUrl: avatarUrl,
      accountId: accountId,
      diagnostics: diagnostics,
    );
  }
}
