class TmdbImageResolver {
  const TmdbImageResolver({this.baseUrl = 'https://image.tmdb.org/t/p/'});

  final String baseUrl;

  Uri? poster(String? path, {String size = 'w342'}) => _build(path, size);
  Uri? backdrop(String? path, {String size = 'w780'}) => _build(path, size);
  Uri? logo(String? path, {String size = 'w300'}) => _build(path, size);
  Uri? still(String? path, {String size = 'w185'}) => _build(path, size);

  Uri? _build(String? path, String size) {
    if (path == null || path.isEmpty) return null;
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$size$normalized');
  }
}
