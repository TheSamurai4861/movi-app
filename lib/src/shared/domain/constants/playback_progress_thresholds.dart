/// Seuils de progression de lecture partagés dans toute l'app.
///
/// Règle produit:
/// - Un contenu est considéré "en cours" si sa progression est comprise
///   entre [minInProgress] (inclus) et [maxInProgress] (exclus).
/// - Un contenu est considéré "terminé" à partir de [maxInProgress].
class PlaybackProgressThresholds {
  PlaybackProgressThresholds._();

  /// Progression minimale (ex: 5%) pour considérer une lecture "en cours".
  static const double minInProgress = 0.05;

  /// Progression maximale (ex: 95%) au-delà de laquelle le contenu est "terminé".
  static const double maxInProgress = 0.95;
}

