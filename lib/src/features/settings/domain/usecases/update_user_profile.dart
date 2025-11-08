import '../entities/user_profile.dart';
import '../repositories/settings_repository.dart';

class UpdateUserProfile {
  const UpdateUserProfile(this._repository);

  final SettingsRepository _repository;

  Future<void> call(UserProfile profile) {
    return _repository.updateProfile(profile);
  }
}
