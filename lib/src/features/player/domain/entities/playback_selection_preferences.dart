import 'package:equatable/equatable.dart';

class PlaybackSelectionPreferences extends Equatable {
  const PlaybackSelectionPreferences({
    this.preferredSourceIds = const <String>{},
    this.preferredAudioLanguageCode,
    this.preferredSubtitleLanguageCode,
    this.preferredQualityRank,
  });

  final Set<String> preferredSourceIds;
  final String? preferredAudioLanguageCode;
  final String? preferredSubtitleLanguageCode;
  final int? preferredQualityRank;

  @override
  List<Object?> get props => <Object?>[
    preferredSourceIds.toList(growable: false)..sort(),
    preferredAudioLanguageCode,
    preferredSubtitleLanguageCode,
    preferredQualityRank,
  ];
}
