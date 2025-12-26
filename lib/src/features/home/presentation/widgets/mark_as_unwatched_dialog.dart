import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_providers.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/features/library/presentation/providers/library_remote_providers.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

/// Affiche un dialog pour marquer un média comme non vu.
void showMarkAsUnwatchedDialog(
  BuildContext context,
  WidgetRef ref,
  String contentId,
  ContentType type,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.visibility_off, color: Colors.white),
            title: const Text(
              'Marquer comme non vu',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () async {
              Navigator.pop(context);
              final historyRepo = ref.read(hybridPlaybackHistoryRepositoryProvider);
              final userId = ref.read(currentUserIdProvider);
              await historyRepo.remove(contentId, type, userId: userId);
              unawaited(
                ref
                    .read(libraryCloudSyncControllerProvider.notifier)
                    .syncNow(reason: 'auto'),
              );
              ref.invalidate(hp.homeInProgressProvider);
              ref.invalidate(libraryPlaylistsProvider);
            },
          ),
        ],
      ),
    ),
  );
}
