/// Abstraction exposée à la couche domaine pour obtenir les contenus
/// (films, séries, playlists, etc.) sans dépendre de l'infrastructure.
abstract class ContentRepository {
  Future<List<String>> fetchContinueWatching();
  Future<List<String>> fetchFeatured();
}
