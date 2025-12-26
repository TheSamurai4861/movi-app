import 'package:equatable/equatable.dart';

import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';

class XtreamPlaylistSettings extends Equatable {
  const XtreamPlaylistSettings({
    required this.accountId,
    required this.playlistId,
    required this.type,
    required this.position,
    required this.globalPosition,
    required this.isVisible,
    required this.updatedAt,
  });

  final String accountId;
  final String playlistId;
  final XtreamPlaylistType type;
  final int position;
  final int globalPosition;
  final bool isVisible;
  final DateTime updatedAt;

  XtreamPlaylistSettings copyWith({
    int? position,
    int? globalPosition,
    bool? isVisible,
    DateTime? updatedAt,
  }) {
    return XtreamPlaylistSettings(
      accountId: accountId,
      playlistId: playlistId,
      type: type,
      position: position ?? this.position,
      globalPosition: globalPosition ?? this.globalPosition,
      isVisible: isVisible ?? this.isVisible,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    accountId,
    playlistId,
    type,
    position,
    globalPosition,
    isVisible,
    updatedAt,
  ];
}
