import 'package:movi/src/features/settings/domain/entities/user_settings.dart';

abstract class UserSettingsRepository {
  Future<void> save(UserSettings profile);
  Future<UserSettings?> load();
}
