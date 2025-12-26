import 'package:equatable/equatable.dart';

import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/value_objects/synopsis.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class Playlist extends Equatable {
  const Playlist({
    required this.id,
    required this.title,
    this.description,
    this.cover,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    required this.owner,
    this.isPublic = true,
    this.totalDuration,
  });

  final PlaylistId id;
  final MediaTitle title;
  final Synopsis? description;
  final Uri? cover;
  final List<PlaylistItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String owner;
  final bool isPublic;
  final Duration? totalDuration;

  int get totalItems => items.length;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    cover,
    items,
    createdAt,
    updatedAt,
    owner,
    isPublic,
    totalDuration,
  ];
}

class PlaylistItem extends Equatable {
  const PlaylistItem({
    required this.reference,
    this.position,
    this.addedAt,
    this.runtime,
    this.notes,
  });

  final ContentReference reference;
  final int? position;
  final DateTime? addedAt;
  final Duration? runtime;
  final String? notes;

  @override
  List<Object?> get props => [reference, position, addedAt, runtime, notes];
}

class PlaylistSummary extends Equatable {
  const PlaylistSummary({
    required this.id,
    required this.title,
    this.cover,
    this.itemCount,
    this.owner,
    this.isPinned = false,
  });

  final PlaylistId id;
  final MediaTitle title;
  final Uri? cover;
  final int? itemCount;
  final String? owner;
  final bool isPinned;

  @override
  List<Object?> get props => [id, title, cover, itemCount, owner, isPinned];
}
