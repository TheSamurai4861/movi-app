import 'package:movi/src/features/settings/domain/entities/user_settings.dart';
import 'package:movi/src/features/settings/domain/repositories/settings_repository.dart';

class UpdateUserProfile {
  const UpdateUserProfile(this._repository);

  final SettingsRepository _repository;

  Future<void> call(UserSettings profile) {
    return _repository.updateProfile(profile);
  }
}
