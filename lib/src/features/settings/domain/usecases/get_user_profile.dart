import 'package:movi/src/features/settings/domain/entities/user_profile.dart';
import 'package:movi/src/features/settings/domain/repositories/settings_repository.dart';

class GetUserProfile {
  const GetUserProfile(this._repository);

  final SettingsRepository _repository;

  Future<UserProfile> call() => _repository.getUserProfile();
}
