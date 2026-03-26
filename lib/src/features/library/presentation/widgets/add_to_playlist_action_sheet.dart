import 'package:flutter/cupertino.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';

Future<void> showAddToPlaylistActionSheet({
  required BuildContext context,
  required AppLocalizations l10n,
  required List<LibraryPlaylistItem> playlists,
  required Future<void> Function(LibraryPlaylistItem playlist) onSelect,
}) {
  return showCupertinoModalPopup<void>(
    context: context,
    builder: (ctx) {
      return CupertinoActionSheet(
        title: Text(l10n.actionAddToList),
        actions: playlists
            .map(
              (playlist) => CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await onSelect(playlist);
                },
                child: Text(playlist.title),
              ),
            )
            .toList(growable: false),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.actionCancel),
        ),
      );
    },
  );
}
