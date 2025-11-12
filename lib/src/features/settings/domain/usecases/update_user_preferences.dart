import 'package:movi/src/features/settings/domain/entities/user_preferences.dart';
import 'package:movi/src/features/settings/domain/repositories/settings_repository.dart';

class UpdateUserPreferences {
  const UpdateUserPreferences(this._repository);

  final SettingsRepository _repository;

  Future<void> call(UserPreferences preferences) {
    return _repository.updatePreferences(preferences);
  }
}
