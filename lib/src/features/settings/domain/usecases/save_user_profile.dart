import 'package:movi/src/features/settings/domain/entities/user_settings.dart';
import 'package:movi/src/features/settings/domain/repositories/user_settings_repository.dart';

class SaveUserProfile {
  const SaveUserProfile(this._repo);
  final UserSettingsRepository _repo;

  Future<void> call(UserSettings profile) => _repo.save(profile);
}
