import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/images/image_prefetch_coordinator.dart';
import 'package:movi/src/core/images/image_prefetch_policy.dart';

void main() {
  group('ImagePrefetchCoordinator', () {
    final coordinator = ImagePrefetchCoordinator.instance;

    setUp(coordinator.resetForTest);

    test('deduplicates identical urls in one enqueue call', () {
      coordinator.enqueueUrlsForTest(
        const [
          'https://image.tmdb.org/t/p/w500/a.jpg',
          'https://image.tmdb.org/t/p/w500/a.jpg',
        ],
      );

      expect(coordinator.trackedUrlCountForTest, 1);
    });

    test('downgrades TMDB urls on television policy before enqueue', () {
      coordinator.enqueueUrlsForTest(
        const ['https://image.tmdb.org/t/p/w1280/hero.jpg'],
        policyOverride: ImagePrefetchPolicy.television,
        reason: ImagePrefetchReason.legacyHeroOverlay,
      );

      expect(coordinator.trackedUrlCountForTest, 1);
      expect(
        coordinator.peekQueuedUrlForTest(),
        'https://image.tmdb.org/t/p/w780/hero.jpg',
      );
    });

    test('ignores non-http urls', () {
      coordinator.enqueueUrlsForTest(
        const ['asset://poster.png', ''],
      );

      expect(coordinator.trackedUrlCountForTest, 0);
    });

    test('respects maxItems override', () {
      coordinator.enqueueUrlsForTest(
        List.generate(
          6,
          (index) => 'https://example.com/$index.jpg',
        ),
        maxItems: 2,
      );

      expect(coordinator.trackedUrlCountForTest, 2);
    });
  });
}
