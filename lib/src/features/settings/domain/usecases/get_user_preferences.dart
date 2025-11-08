import '../entities/user_preferences.dart';
import '../repositories/settings_repository.dart';

class GetUserPreferences {
  const GetUserPreferences(this._repository);

  final SettingsRepository _repository;

  Future<UserPreferences> call() => _repository.getPreferences();
}
