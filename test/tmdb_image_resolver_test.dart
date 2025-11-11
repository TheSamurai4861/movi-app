import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';

void main() {
  group('TmdbImageResolver', () {
    const resolver = TmdbImageResolver();

    test('poster builds w342 URL with leading slash normalized', () {
      final uri = resolver.poster('abc.jpg', size: 'w342');
      expect(uri?.toString(), 'https://image.tmdb.org/t/p/w342/abc.jpg');
    });

    test('backdrop builds w780 URL', () {
      final uri = resolver.backdrop('/xyz.jpg', size: 'w780');
      expect(uri?.toString(), 'https://image.tmdb.org/t/p/w780/xyz.jpg');
    });

    test('returns null when path is null or empty', () {
      expect(resolver.poster(null), isNull);
      expect(resolver.backdrop(''), isNull);
    });
  });
}