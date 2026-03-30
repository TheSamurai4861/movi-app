import 'package:equatable/equatable.dart';
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

enum PlaybackSelectionDisposition { autoPlay, manualSelection, unavailable }

enum PlaybackSelectionReason {
  noPlayableVariant,
  singlePlayableVariant,
  preferredSourceMatch,
  preferredAudioLanguageMatch,
  preferredSubtitleLanguageMatch,
  preferredQualityMatch,
  deterministicFallback,
  ambiguousVariants,
  preferredVariantUnavailable,
}

class PlaybackSelectionContext extends Equatable {
  const PlaybackSelectionContext({
    required this.contentType,
    this.allowManualSelection = true,
  });

  final ContentType contentType;
  final bool allowManualSelection;

  @override
  List<Object?> get props => <Object?>[contentType, allowManualSelection];
}

class PlaybackSelectionDecision extends Equatable {
  const PlaybackSelectionDecision({
    required this.disposition,
    required this.reason,
    required this.rankedVariants,
    this.selectedVariant,
  });

  final PlaybackSelectionDisposition disposition;
  final PlaybackSelectionReason reason;
  final List<PlaybackVariant> rankedVariants;
  final PlaybackVariant? selectedVariant;

  bool get requiresManualSelection =>
      disposition == PlaybackSelectionDisposition.manualSelection;

  bool get hasManualSelectionAvailable => rankedVariants.length > 1;

  bool get isUnavailable =>
      disposition == PlaybackSelectionDisposition.unavailable;

  @override
  List<Object?> get props => <Object?>[
    disposition,
    reason,
    rankedVariants,
    selectedVariant,
  ];
}
