/// Abstraction que la couche data devra implémenter pour fournir les
/// contenus (films, séries, playlists, etc.).
abstract class ContentRepository {
  Future<List<String>> fetchContinueWatching();
  Future<List<String>> fetchFeatured();
}
