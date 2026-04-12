import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/images/app_image_cache_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppImageCacheManager', () {
    test('exposes expected cache policy constants', () {
      expect(AppImageCacheManager.stalePeriod, const Duration(days: 7));
      expect(AppImageCacheManager.maxCacheObjects, 1000);
      expect(AppImageCacheManager.approxMaxCacheBytes, 400 * 1024 * 1024);
    });

    test('uses singleton instance', () {
      expect(
        identical(
          AppImageCacheManager.instance,
          AppImageCacheManager.instance,
        ),
        isTrue,
      );
    });
  });
}
