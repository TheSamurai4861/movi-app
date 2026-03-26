/// Constantes métier pour la feature Library.
///
/// Centralise les IDs logiques utilisés dans les playlists de bibliothèque
/// ainsi que les seuils de progression pour l'historique.
class LibraryConstants {
  LibraryConstants._();

  // Identifiants logiques de playlists "systèmes"
  static const String inProgressPlaylistId = 'in_progress';
  static const String favoriteMoviesPlaylistId = 'favorite_movies';
  static const String favoriteSeriesPlaylistId = 'favorite_series';
  static const String watchHistoryPlaylistId = 'watch_history';

  // Préfixes pour les IDs de playlists dérivés
  static const String sagaPrefix = 'saga_';
  static const String actorPrefix = 'actor_';
  static const String userPlaylistPrefix = 'playlist_';

  // Seuils métier
  /// Progression minimale pour considérer un média comme "en cours".
  static const double inProgressMinThreshold = 0.05;
  /// Seuil de progression pour inclure un média dans l'historique "vu".
  static const double watchHistoryCompletedThreshold = 0.9;
  /// Seuil max exclusif pour considérer un média comme "en cours".
  static const double inProgressMaxThreshold = 0.95;
}
