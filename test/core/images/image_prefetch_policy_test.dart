import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/images/image_prefetch_policy.dart';

void main() {
  group('ImagePrefetchPolicy', () {
    test('television limits concurrent prefetch and memory precache', () {
      const policy = ImagePrefetchPolicy.television;
      expect(policy.maxConcurrent, 2);
      expect(policy.allowMemoryPrecache, isFalse);
      expect(policy.prefetchTimeout, const Duration(seconds: 6));
      expect(policy.isTvLayout, isTrue);
    });

    test('standard allows memory precache with higher playlist cap', () {
      const policy = ImagePrefetchPolicy.standard;
      expect(policy.allowMemoryPrecache, isTrue);
      expect(policy.maxUrlsFor(ImagePrefetchReason.libraryPlaylists), 32);
      expect(policy.maxUrlsFor(ImagePrefetchReason.continueWatching), 14);
    });

    test('maxUrlsFor falls back to generic cap', () {
      const policy = ImagePrefetchPolicy.diskOnly;
      expect(policy.maxUrlsFor(ImagePrefetchReason.generic), 12);
    });
  });
}
