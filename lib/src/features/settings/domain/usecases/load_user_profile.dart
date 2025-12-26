import 'package:movi/src/features/settings/domain/entities/user_settings.dart';
import 'package:movi/src/features/settings/domain/repositories/user_settings_repository.dart';

class LoadUserProfile {
  const LoadUserProfile(this._repo);
  final UserSettingsRepository _repo;

  Future<UserSettings?> call() => _repo.load();
}
