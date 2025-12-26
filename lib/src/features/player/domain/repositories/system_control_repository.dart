/// Interface pour le contrôle de la luminosité et du volume système.
/// 
/// Cette interface définit le contrat pour contrôler la luminosité de l'écran
/// et le volume système sans dépendances vers des packages Flutter spécifiques.
abstract class SystemControlRepository {
  /// Récupère la luminosité actuelle de l'écran.
  /// 
  /// Retourne une valeur entre 0.0 (minimum) et 1.0 (maximum).
  Future<double> getBrightness();

  /// Définit la luminosité de l'écran.
  /// 
  /// [brightness] doit être entre 0.0 (minimum) et 1.0 (maximum).
  /// Les valeurs hors limites seront automatiquement clampées.
  Future<void> setBrightness(double brightness);

  /// Libère le contrôle de la luminosité de l'écran.
  /// 
  /// Permet au système de reprendre le contrôle de la luminosité,
  /// permettant à l'utilisateur de la modifier via le menu système.
  Future<void> resetBrightness();

  /// Récupère le volume système actuel.
  /// 
  /// Retourne une valeur entre 0.0 (silencieux) et 1.0 (maximum).
  Future<double> getVolume();

  /// Définit le volume système.
  /// 
  /// [volume] doit être entre 0.0 (silencieux) et 1.0 (maximum).
  /// Les valeurs hors limites seront automatiquement clampées.
  Future<void> setVolume(double volume);
}

