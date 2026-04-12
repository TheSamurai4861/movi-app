import 'package:flutter/foundation.dart';
import 'package:movi/src/core/config/config.dart';
import 'package:movi/src/core/di/di.dart';

@immutable
class ImageLoadingPolicy {
  const ImageLoadingPolicy({
    required this.enableDiskCache,
    required this.enableCachedNetworkPath,
    required this.forceNetworkFallbackOnly,
  });

  final bool enableDiskCache;
  final bool enableCachedNetworkPath;
  final bool forceNetworkFallbackOnly;

  static const defaults = ImageLoadingPolicy(
    enableDiskCache: true,
    enableCachedNetworkPath: true,
    forceNetworkFallbackOnly: false,
  );
}

class ImageLoadingPolicyService {
  const ImageLoadingPolicyService._();

  static ImageLoadingPolicy resolve() {
    if (!sl.isRegistered<AppConfig>()) return ImageLoadingPolicy.defaults;
    final flags = sl<AppConfig>().featureFlags;
    return ImageLoadingPolicy(
      enableDiskCache: flags.enableImageDiskCache,
      enableCachedNetworkPath: flags.enableImageCachedNetworkPath,
      forceNetworkFallbackOnly: flags.forceImageNetworkFallbackOnly,
    );
  }
}
