import 'package:movi/src/features/player/domain/entities/playback_selection_decision.dart';
import 'package:movi/src/features/player/domain/entities/playback_selection_preferences.dart';
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';

class PlaybackSelectionService {
  const PlaybackSelectionService();

  PlaybackSelectionDecision select({
    required List<PlaybackVariant> variants,
    required PlaybackSelectionPreferences preferences,
    required PlaybackSelectionContext context,
  }) {
    if (variants.isEmpty) {
      return const PlaybackSelectionDecision(
        disposition: PlaybackSelectionDisposition.unavailable,
        reason: PlaybackSelectionReason.noPlayableVariant,
        rankedVariants: <PlaybackVariant>[],
      );
    }

    final ranked =
        variants
            .map(
              (variant) => (
                variant: variant,
                ranking: _PlaybackVariantRanking.fromVariant(
                  variant,
                  preferences: preferences,
                ),
              ),
            )
            .toList(growable: false)
          ..sort((left, right) => left.ranking.compareTo(right.ranking));

    final rankedVariants = ranked
        .map((entry) => entry.variant)
        .toList(growable: false);

    if (rankedVariants.length == 1) {
      return PlaybackSelectionDecision(
        disposition: PlaybackSelectionDisposition.autoPlay,
        reason: PlaybackSelectionReason.singlePlayableVariant,
        rankedVariants: rankedVariants,
        selectedVariant: rankedVariants.first,
      );
    }

    final first = ranked.first;
    final second = ranked[1];
    final isAmbiguous = first.ranking.hasSamePriorityAs(second.ranking);

    if (isAmbiguous && context.allowManualSelection) {
      return PlaybackSelectionDecision(
        disposition: PlaybackSelectionDisposition.manualSelection,
        reason: PlaybackSelectionReason.ambiguousVariants,
        rankedVariants: rankedVariants,
      );
    }

    final topVariant = first.variant;
    final hasExplicitTrackPreferences =
        (preferences.preferredAudioLanguageCode?.isNotEmpty ?? false) ||
        (preferences.preferredSubtitleLanguageCode?.isNotEmpty ?? false);
    final satisfiesExplicitTrackPreferences = _matchesExplicitTrackPreferences(
      topVariant,
      preferences: preferences,
    );
    if (rankedVariants.length > 1 &&
        hasExplicitTrackPreferences &&
        !satisfiesExplicitTrackPreferences &&
        context.allowManualSelection) {
      return PlaybackSelectionDecision(
        disposition: PlaybackSelectionDisposition.manualSelection,
        reason: PlaybackSelectionReason.preferredVariantUnavailable,
        rankedVariants: rankedVariants,
      );
    }

    return PlaybackSelectionDecision(
      disposition: PlaybackSelectionDisposition.autoPlay,
      reason: _resolveReason(
        first: first.ranking,
        second: second.ranking,
        preferences: preferences,
      ),
      rankedVariants: rankedVariants,
      selectedVariant: topVariant,
    );
  }

  bool _matchesExplicitTrackPreferences(
    PlaybackVariant variant, {
    required PlaybackSelectionPreferences preferences,
  }) {
    final preferredAudio = preferences.preferredAudioLanguageCode?.trim();
    final preferredSubtitle = preferences.preferredSubtitleLanguageCode?.trim();

    final audioMatches =
        preferredAudio == null ||
        preferredAudio.isEmpty ||
        variant.audioLanguageCode == preferredAudio;
    final subtitleMatches =
        preferredSubtitle == null ||
        preferredSubtitle.isEmpty ||
        variant.subtitleLanguageCode == preferredSubtitle;

    return audioMatches && subtitleMatches;
  }

  PlaybackSelectionReason _resolveReason({
    required _PlaybackVariantRanking first,
    required _PlaybackVariantRanking second,
    required PlaybackSelectionPreferences preferences,
  }) {
    if (first.audioScore != second.audioScore) {
      return PlaybackSelectionReason.preferredAudioLanguageMatch;
    }
    if (first.subtitleScore != second.subtitleScore) {
      return PlaybackSelectionReason.preferredSubtitleLanguageMatch;
    }
    if (preferences.preferredQualityRank != null &&
        first.qualityPreferenceScore != second.qualityPreferenceScore) {
      return PlaybackSelectionReason.preferredQualityMatch;
    }
    return PlaybackSelectionReason.deterministicFallback;
  }
}

class _PlaybackVariantRanking {
  const _PlaybackVariantRanking({
    required this.audioScore,
    required this.subtitleScore,
    required this.qualityPreferenceScore,
    required this.qualityKnownScore,
    required this.qualityRank,
    required this.sourceLabel,
    required this.variantId,
  });

  factory _PlaybackVariantRanking.fromVariant(
    PlaybackVariant variant, {
    required PlaybackSelectionPreferences preferences,
  }) {
    return _PlaybackVariantRanking(
      audioScore: _matchScore(
        preferredCode: preferences.preferredAudioLanguageCode,
        variantCode: variant.audioLanguageCode,
      ),
      subtitleScore: _matchScore(
        preferredCode: preferences.preferredSubtitleLanguageCode,
        variantCode: variant.subtitleLanguageCode,
      ),
      qualityPreferenceScore: _qualityPreferenceScore(
        preferredQualityRank: preferences.preferredQualityRank,
        variantQualityRank: variant.qualityRank,
      ),
      qualityKnownScore: variant.qualityRank == null ? 0 : 1,
      qualityRank: variant.qualityRank ?? 0,
      sourceLabel: variant.sourceLabel.toLowerCase(),
      variantId: variant.id,
    );
  }

  final int audioScore;
  final int subtitleScore;
  final int qualityPreferenceScore;
  final int qualityKnownScore;
  final int qualityRank;
  final String sourceLabel;
  final String variantId;

  int compareTo(_PlaybackVariantRanking other) {
    final comparableScores = <(int left, int right)>[
      (audioScore, other.audioScore),
      (subtitleScore, other.subtitleScore),
      (qualityPreferenceScore, other.qualityPreferenceScore),
      (qualityKnownScore, other.qualityKnownScore),
      (qualityRank, other.qualityRank),
    ];

    for (final score in comparableScores) {
      final delta = score.$2.compareTo(score.$1);
      if (delta != 0) {
        return delta;
      }
    }

    final sourceDelta = sourceLabel.compareTo(other.sourceLabel);
    if (sourceDelta != 0) {
      return sourceDelta;
    }

    return variantId.compareTo(other.variantId);
  }

  bool hasSamePriorityAs(_PlaybackVariantRanking other) {
    return audioScore == other.audioScore &&
        subtitleScore == other.subtitleScore &&
        qualityPreferenceScore == other.qualityPreferenceScore &&
        qualityKnownScore == other.qualityKnownScore &&
        qualityRank == other.qualityRank;
  }

  static int _matchScore({
    required String? preferredCode,
    required String? variantCode,
  }) {
    if (preferredCode == null || preferredCode.isEmpty) {
      return 0;
    }
    if (variantCode == preferredCode) {
      return 2;
    }
    if (variantCode == null || variantCode.isEmpty) {
      return 1;
    }
    return 0;
  }

  static int _qualityPreferenceScore({
    required int? preferredQualityRank,
    required int? variantQualityRank,
  }) {
    if (preferredQualityRank == null) {
      return 0;
    }
    if (variantQualityRank == null) {
      return 0;
    }

    final delta = variantQualityRank - preferredQualityRank;
    if (delta == 0) {
      return 500;
    }
    if (delta < 0) {
      return 400 - delta.abs();
    }
    return 200 - delta;
  }
}
