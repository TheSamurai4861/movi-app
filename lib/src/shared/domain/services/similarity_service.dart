abstract class SimilarityService {
  /// Calcule un score de similarité entre [original] et [result].
  /// Retourne une valeur comprise entre 0.0 et 1.0.
  double score(String original, String result);
}
