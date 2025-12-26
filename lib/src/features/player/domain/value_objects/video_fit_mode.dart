/// Mode d'affichage vidéo pour le player.
///
/// Détermine comment la vidéo est affichée par rapport à l'espace disponible.
enum VideoFitMode {
  /// Respecte les proportions originales (peut avoir des bandes noires).
  contain,

  /// Remplit tout l'espace disponible (peut couper l'image).
  cover;

  /// Convertit le mode en string pour la sérialisation.
  String toValue() {
    switch (this) {
      case VideoFitMode.contain:
        return 'contain';
      case VideoFitMode.cover:
        return 'cover';
    }
  }

  /// Crée un VideoFitMode depuis une string.
  static VideoFitMode? fromValue(String? value) {
    switch (value) {
      case 'contain':
        return VideoFitMode.contain;
      case 'cover':
        return VideoFitMode.cover;
      default:
        return null;
    }
  }
}

