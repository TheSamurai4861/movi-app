import 'package:movi/src/core/preferences/selected_profile_preferences.dart';

/// Service applicatif qui gÃƒÆ’Ã‚Â¨re l'ÃƒÆ’Ã‚Â©tat "profil sÃƒÆ’Ã‚Â©lectionnÃƒÆ’Ã‚Â©".
///
/// Clean:
/// - Pas de Riverpod ici
/// - Pas de UI ici
/// - Encapsule la source (Preferences) pour rendre le reste testable.
class SelectedProfileService {
  SelectedProfileService(this._prefs);

  final SelectedProfilePreferences _prefs;

  String? get selectedProfileId => _prefs.selectedProfileId;

  Stream<String?> get selectedProfileIdStream => _prefs.selectedProfileIdStream;

  Future<void> setSelectedProfileId(String? id) => _prefs.setSelectedProfileId(id);

  Future<void> clear() => _prefs.setSelectedProfileId(null);
}
