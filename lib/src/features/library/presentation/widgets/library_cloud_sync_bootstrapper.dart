import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_access_providers.dart';
import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_providers.dart';

class LibraryCloudSyncBootstrapper extends ConsumerWidget {
  const LibraryCloudSyncBootstrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldBootstrap = ref.watch(shouldBootstrapLibraryCloudSyncProvider);

    // The cloud sync controller must only be mounted when the effective cloud
    // sync rule is satisfied:
    // userWantsCloudSync && isAuthenticated && hasPremiumEntitlement.
    if (shouldBootstrap) {
      ref.watch(libraryCloudSyncControllerProvider);
    }

    return child;
  }
}
