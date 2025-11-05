/// Abstraction that will provide movies, series and related content.
abstract class ContentRepository {
  Future<List<String>> fetchContinueWatching();
  Future<List<String>> fetchFeatured();
}

class FakeContentRepository implements ContentRepository {
  @override
  Future<List<String>> fetchContinueWatching() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return const ['Movie 1', 'Movie 2', 'Series 1'];
  }

  @override
  Future<List<String>> fetchFeatured() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return const ['Featured A', 'Featured B', 'Featured C'];
  }
}
