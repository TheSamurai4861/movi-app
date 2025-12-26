/// Service pour vérifier si un genre TMDB est approprié pour un profil selon le PEGI.
///
/// Utilise une map des IDs de genres TMDB vers les PEGI minimum requis.
/// Permet de bloquer l'accès aux genres inappropriés avant même de charger les résultats.
///
/// **Logique de filtrage** :
/// Un genre est bloqué seulement si > 80% de ses contenus sont inappropriés pour
/// la tranche PEGI. Les genres avec beaucoup de contenus OK (ex: Action, Adventure,
/// Drama) ne sont pas bloqués, laissant le filtrage individuel gérer les cas limites.
///
/// **Genres bloqués** :
/// - Genres PEGI 12 minimum : Crime, War, Film-Noir, War & Politics (séries), Drama (séries) (> 80% des contenus sont PEGI 12+)
/// - Genres PEGI 16 minimum : Horror, Thriller (> 80% des contenus sont PEGI 16+)
///
/// **Genres non bloqués** (beaucoup de contenus OK) :
/// - Action, Adventure, Mystery, Sci-Fi, Fantasy, Comedy, Romance, etc.
class GenreMaturityChecker {
  GenreMaturityChecker._();

  /// Map des IDs de genres TMDB vers PEGI minimum requis.
  ///
  /// Seuil de décision : Un genre est bloqué seulement si > 80% de ses contenus
  /// sont inappropriés pour la tranche PEGI. Les genres avec beaucoup de contenus
  /// OK (ex: Action, Adventure) ne sont pas bloqués, laissant le filtrage
  /// individuel gérer les cas limites.
  static const Map<int, int> _genreMinPegi = {
    // PEGI 12 minimum (> 80% des contenus sont PEGI 12+)
    80: 12,      // Crime - > 85% des films de crime sont PEGI 12+
    10752: 12,   // War (films) - > 80% des films de guerre sont PEGI 12+
    10770: 12,   // Film-Noir - > 85% des films noir sont PEGI 12+
    10768: 12,   // War & Politics (séries) - > 80% des séries guerre/politique sont PEGI 12+
    18: 12,      // Drama (séries) - contenu mature fréquent dans les séries dramatiques
    
    // PEGI 16 minimum (> 80% des contenus sont PEGI 16+)
    27: 16,      // Horror - > 95% des films d'horreur sont PEGI 16+
    53: 16,      // Thriller - > 90% des thrillers sont PEGI 16+
  };

  /// Vérifie si un genre est autorisé pour un profil avec un PEGI donné
  ///
  /// Retourne `true` si le genre est autorisé, `false` sinon.
  /// Si `profilePegi` est `null`, retourne toujours `true` (pas de restriction).
  static bool isGenreAllowed(int genreId, int? profilePegi) {
    if (profilePegi == null) return true;
    final minPegi = _genreMinPegi[genreId];
    if (minPegi == null) return true;
    return profilePegi >= minPegi;
  }

  /// Retourne le PEGI minimum requis pour un genre, ou `null` si pas de restriction
  static int? getMinPegiForGenre(int genreId) {
    return _genreMinPegi[genreId];
  }
}

