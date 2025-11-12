import '../entities/user_profile.dart';
import '../repositories/user_settings_repository.dart';

class SaveUserProfile {
  const SaveUserProfile(this._repo);
  final UserSettingsRepository _repo;

  Future<void> call(UserProfile profile) => _repo.save(profile);
}