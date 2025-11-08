import '../entities/user_preferences.dart';
import '../entities/user_profile.dart';

abstract class SettingsRepository {
  Future<UserPreferences> getPreferences();
  Future<void> updatePreferences(UserPreferences preferences);
  Future<UserProfile> getUserProfile();
  Future<void> updateProfile(UserProfile profile);
}
