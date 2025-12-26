/// Abstraction domaine pour la persistance des préférences utilisateur.
abstract class PreferencesService {
  Future<void> setDarkMode(bool enabled);
  Future<bool> isDarkModeEnabled();
}
