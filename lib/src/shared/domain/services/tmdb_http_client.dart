/// Abstraction HTTP pour interroger TMDB.
abstract class TmdbHttpClient {
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
    String? language,
  });

  Future<List<dynamic>> getJsonList(
    String path, {
    Map<String, Object?>? query,
    String? language,
  });
}
