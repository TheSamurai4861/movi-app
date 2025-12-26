import 'package:equatable/equatable.dart';

import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/value_objects/synopsis.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class Saga extends Equatable {
  const Saga({
    required this.id,
    this.tmdbId,
    required this.title,
    this.synopsis,
    this.cover,
    this.timeline = const [],
    this.tags = const [],
    this.updatedAt,
  });

  final SagaId id;
  final int? tmdbId;
  final MediaTitle title;
  final Synopsis? synopsis;
  final Uri? cover;
  final List<SagaEntry> timeline;
  final List<String> tags;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
    id,
    tmdbId,
    title,
    synopsis,
    cover,
    timeline,
    tags,
    updatedAt,
  ];
}

class SagaEntry extends Equatable {
  const SagaEntry({
    required this.reference,
    this.order,
    this.timelineYear,
    this.duration,
    this.notes,
  });

  final ContentReference reference;
  final int? order;
  final int? timelineYear;
  final Duration? duration;
  final String? notes;

  @override
  List<Object?> get props => [reference, order, timelineYear, duration, notes];
}

class SagaSummary extends Equatable {
  const SagaSummary({
    required this.id,
    this.tmdbId,
    required this.title,
    this.cover,
    this.itemCount,
  });

  final SagaId id;
  final int? tmdbId;
  final MediaTitle title;
  final Uri? cover;
  final int? itemCount;

  @override
  List<Object?> get props => [id, tmdbId, title, cover, itemCount];
}
