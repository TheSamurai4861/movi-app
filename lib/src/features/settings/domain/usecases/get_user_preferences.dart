import 'package:movi/src/features/settings/domain/entities/user_preferences.dart';
import 'package:movi/src/features/settings/domain/repositories/settings_repository.dart';

class GetUserPreferences {
  const GetUserPreferences(this._repository);

  final SettingsRepository _repository;

  Future<UserPreferences> call() => _repository.getPreferences();
}
