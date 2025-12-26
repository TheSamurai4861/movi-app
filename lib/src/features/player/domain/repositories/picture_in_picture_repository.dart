/// Interface pour la gestion du Picture-in-Picture
abstract class PictureInPictureRepository {
  /// Vérifie si le PiP est supporté sur la plateforme actuelle
  Future<bool> isSupported();

  /// Entre en mode PiP
  Future<void> enter();

  /// Sort du mode PiP
  Future<void> exit();

  /// Vérifie si on est actuellement en mode PiP
  Stream<bool> get isActiveStream;

  /// Retourne le WindowController de la fenêtre PiP (null sur toutes les plateformes)
  /// Permet d'envoyer des messages à la fenêtre PiP si nécessaire
  dynamic get windowController;

  /// Libère les ressources
  void dispose();
}

