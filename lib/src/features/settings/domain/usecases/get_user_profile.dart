import '../entities/user_profile.dart';
import '../repositories/settings_repository.dart';

class GetUserProfile {
  const GetUserProfile(this._repository);

  final SettingsRepository _repository;

  Future<UserProfile> call() => _repository.getUserProfile();
}
