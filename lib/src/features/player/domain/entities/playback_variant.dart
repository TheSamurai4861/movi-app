import 'package:equatable/equatable.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class PlaybackVariant extends Equatable {
  const PlaybackVariant({
    required this.id,
    required this.sourceId,
    required this.sourceLabel,
    required this.videoSource,
    required this.contentType,
    required this.rawTitle,
    required this.normalizedTitle,
    this.qualityLabel,
    this.qualityRank,
    this.dynamicRangeLabel,
    this.audioLanguageCode,
    this.audioLanguageLabel,
    this.subtitleLanguageCode,
    this.subtitleLanguageLabel,
    this.hasSubtitles,
  });

  final String id;
  final String sourceId;
  final String sourceLabel;
  final VideoSource videoSource;
  final ContentType contentType;
  final String rawTitle;
  final String normalizedTitle;
  final String? qualityLabel;
  final int? qualityRank;
  final String? dynamicRangeLabel;
  final String? audioLanguageCode;
  final String? audioLanguageLabel;
  final String? subtitleLanguageCode;
  final String? subtitleLanguageLabel;
  final bool? hasSubtitles;

  @override
  List<Object?> get props => <Object?>[
    id,
    sourceId,
    sourceLabel,
    videoSource,
    contentType,
    rawTitle,
    normalizedTitle,
    qualityLabel,
    qualityRank,
    dynamicRangeLabel,
    audioLanguageCode,
    audioLanguageLabel,
    subtitleLanguageCode,
    subtitleLanguageLabel,
    hasSubtitles,
  ];
}
