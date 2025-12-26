import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_providers.dart';

class LibraryCloudSyncBootstrapper extends ConsumerWidget {
  const LibraryCloudSyncBootstrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensures the controller is mounted early so it can listen to profile/client
    // changes and run background sync.
    ref.watch(libraryCloudSyncControllerProvider);
    return child;
  }
}

