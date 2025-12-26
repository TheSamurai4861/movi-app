import 'package:movi/src/features/settings/domain/entities/user_settings.dart';
import 'package:movi/src/features/settings/domain/repositories/settings_repository.dart';

class GetUserProfile {
  const GetUserProfile(this._repository);

  final SettingsRepository _repository;

  Future<UserSettings> call() => _repository.getUserProfile();
}
