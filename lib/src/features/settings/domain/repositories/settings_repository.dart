import 'package:movi/src/features/settings/domain/entities/user_preferences.dart';
import 'package:movi/src/features/settings/domain/entities/user_settings.dart';

abstract class SettingsRepository {
  Future<UserPreferences> getPreferences();
  Future<void> updatePreferences(UserPreferences preferences);
  Future<UserSettings> getUserProfile();
  Future<void> updateProfile(UserSettings profile);
}
