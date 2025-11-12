import '../entities/user_profile.dart';
import '../repositories/user_settings_repository.dart';

class LoadUserProfile {
  const LoadUserProfile(this._repo);
  final UserSettingsRepository _repo;

  Future<UserProfile?> call() => _repo.load();
}