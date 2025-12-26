import 'package:movi/src/core/profile/domain/repositories/profile_repository.dart';

/// Use case: supprimer un profil.
class DeleteProfileUseCase {
  const DeleteProfileUseCase(this._repo);

  final ProfileRepository _repo;

  Future<void> call(
    String profileId, {
    bool? diagnostics,
  }) {
    return _repo.deleteProfile(
      profileId,
      diagnostics: diagnostics,
    );
  }
}
