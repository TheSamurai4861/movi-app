import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';

void main() {
  group('TmdbImageResolver sizing helpers', () {
    late TmdbImageResolver resolver;

    setUp(() {
      resolver = TmdbImageResolver(baseUrl: 'https://image.tmdb.org/t/p/');
    });

    test('posterSizeForPixelWidth picks smallest covering width', () {
      expect(resolver.posterSizeForPixelWidth(100), 'w154');
      expect(resolver.posterSizeForPixelWidth(350), 'w500');
      expect(resolver.posterSizeForPixelWidth(2000), 'w780');
    });

    test('backdropSizeForPixelWidth picks smallest covering width', () {
      expect(resolver.backdropSizeForPixelWidth(400), 'w780');
      expect(resolver.backdropSizeForPixelWidth(2000), 'w1280');
    });

    test('downgradeHttpUrl replaces TMDB width segment', () {
      const url =
          'https://image.tmdb.org/t/p/w1280/abc.jpg';
      expect(
        TmdbImageResolver.downgradeHttpUrl(url, 'w780'),
        'https://image.tmdb.org/t/p/w780/abc.jpg',
      );
    });

    test('downgradeHttpUrl leaves non-TMDB urls unchanged', () {
      const url = 'https://cdn.example.com/poster.jpg';
      expect(TmdbImageResolver.downgradeHttpUrl(url, 'w500'), url);
    });
  });
}
