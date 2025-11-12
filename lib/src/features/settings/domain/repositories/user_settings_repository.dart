import 'package:movi/src/features/settings/domain/entities/user_profile.dart';

abstract class UserSettingsRepository {
  Future<void> save(UserProfile profile);
  Future<UserProfile?> load();
}
