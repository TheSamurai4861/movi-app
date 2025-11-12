import 'package:equatable/equatable.dart';

import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';

enum XtreamPlaylistType { movies, series }

class XtreamPlaylist extends Equatable {
  const XtreamPlaylist({
    required this.id,
    required this.accountId,
    required this.title,
    required this.type,
    required this.items,
  });

  final String id;
  final String accountId;
  final String title;
  final XtreamPlaylistType type;
  final List<XtreamPlaylistItem> items;

  @override
  List<Object?> get props => [id, accountId, title, type, items];
}
