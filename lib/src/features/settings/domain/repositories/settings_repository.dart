import 'package:movi/src/features/settings/domain/entities/user_preferences.dart';
import 'package:movi/src/features/settings/domain/entities/user_profile.dart';

abstract class SettingsRepository {
  Future<UserPreferences> getPreferences();
  Future<void> updatePreferences(UserPreferences preferences);
  Future<UserProfile> getUserProfile();
  Future<void> updateProfile(UserProfile profile);
}
