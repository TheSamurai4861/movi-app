import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:movi/src/core/images/app_image_cache_manager.dart';
import 'package:movi/src/core/logging/logging_service.dart';

class SafeImageCacheManager {
  const SafeImageCacheManager._();

  static bool _disabledForSession = false;
  static bool _loggedInitFailure = false;

  static BaseCacheManager? tryGet({required bool enabled}) {
    if (!enabled || _disabledForSession) return null;
    try {
      return AppImageCacheManager.instance;
    } catch (error, stackTrace) {
      _disabledForSession = true;
      if (!_loggedInitFailure) {
        _loggedInitFailure = true;
        LoggingService.log(
          '[ImagePipeline] cache_manager_init_failed; falling back to network-only mode',
          category: 'image_pipeline',
          error: error,
          stackTrace: stackTrace,
        );
      }
      return null;
    }
  }
}
