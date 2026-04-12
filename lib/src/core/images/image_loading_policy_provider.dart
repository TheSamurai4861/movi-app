import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/config/providers/config_provider.dart';
import 'package:movi/src/core/images/image_loading_policy.dart';

final imageLoadingPolicyProvider = Provider<ImageLoadingPolicy>((ref) {
  final flags = ref.watch(featureFlagsProvider);
  return ImageLoadingPolicy(
    enableDiskCache: flags.enableImageDiskCache,
    enableCachedNetworkPath: flags.enableImageCachedNetworkPath,
    forceNetworkFallbackOnly: flags.forceImageNetworkFallbackOnly,
  );
});
