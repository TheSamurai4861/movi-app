import 'dart:async';

import 'package:flutter/material.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/widgets/movi_tv_action_menu.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';

Future<void> showAddToPlaylistActionSheet({
  required BuildContext context,
  required AppLocalizations l10n,
  required List<LibraryPlaylistItem> playlists,
  required Future<void> Function(LibraryPlaylistItem playlist) onSelect,
}) {
  final actions = playlists
      .map(
        (playlist) => MoviTvActionMenuAction(
          label: playlist.title,
          onPressed: () {
            unawaited(onSelect(playlist));
          },
        ),
      )
      .toList(growable: false);

  return showMoviTvActionMenu(
    context: context,
    title: l10n.actionAddToList,
    actions: actions,
    cancelLabel: l10n.actionCancel,
  );
}
