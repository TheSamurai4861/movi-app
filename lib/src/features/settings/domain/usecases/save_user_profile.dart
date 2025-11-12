import 'package:movi/src/features/settings/domain/entities/user_profile.dart';
import 'package:movi/src/features/settings/domain/repositories/user_settings_repository.dart';

class SaveUserProfile {
  const SaveUserProfile(this._repo);
  final UserSettingsRepository _repo;

  Future<void> call(UserProfile profile) => _repo.save(profile);
}
