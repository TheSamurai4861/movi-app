/// Abstraction for reading and writing local user preferences.
abstract class PreferencesService {
  Future<void> setDarkMode(bool enabled);
  Future<bool> isDarkModeEnabled();
}

class FakePreferencesService implements PreferencesService {
  bool _darkMode = false;

  @override
  Future<bool> isDarkModeEnabled() async => _darkMode;

  @override
  Future<void> setDarkMode(bool enabled) async {
    _darkMode = enabled;
  }
}
