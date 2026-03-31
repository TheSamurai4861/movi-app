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

    final rankedVariants = _rankVariants(
      variants: variants,
      preferences: preferences,
    );

    if (rankedVariants.length == 1) {
      return PlaybackSelectionDecision(
        disposition: PlaybackSelectionDisposition.autoPlay,
        reason: PlaybackSelectionReason.singlePlayableVariant,
        rankedVariants: rankedVariants,
        selectedVariant: rankedVariants.first,
      );
    }

    // Auto-selection is intentionally disabled when multiple playback variants
    // are available. Even if persisted preferences exist, the user must choose
    // the variant manually for movie and episode flows.
    if (context.allowManualSelection) {
      return PlaybackSelectionDecision(
        disposition: PlaybackSelectionDisposition.manualSelection,
        reason: PlaybackSelectionReason.ambiguousVariants,
        rankedVariants: rankedVariants,
      );
    }

    return PlaybackSelectionDecision(
      disposition: PlaybackSelectionDisposition.autoPlay,
      reason: PlaybackSelectionReason.deterministicFallback,
      rankedVariants: rankedVariants,
      selectedVariant: rankedVariants.first,
    );
  }

  List<PlaybackVariant> _rankVariants({
    required List<PlaybackVariant> variants,
    required PlaybackSelectionPreferences preferences,
  }) {
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

    return ranked.map((entry) => entry.variant).toList(growable: false);
  }
}

class _PlaybackVariantRanking implements Comparable<_PlaybackVariantRanking> {
  const _PlaybackVariantRanking({
    required this.preferredSourceOrder,
    required this.preferredAudioOrder,
    required this.preferredSubtitleOrder,
    required this.preferredQualityOrder,
    required this.qualityOrder,
    required this.sourceLabelOrder,
    required this.titleOrder,
    required this.variantIdOrder,
  });

  factory _PlaybackVariantRanking.fromVariant(
    PlaybackVariant variant, {
    required PlaybackSelectionPreferences preferences,
  }) {
    return _PlaybackVariantRanking(
      preferredSourceOrder: _preferredSourceOrder(
        variant.sourceId,
        preferences.preferredSourceIds,
      ),
      preferredAudioOrder: _preferredLanguageOrder(
        preferredLanguageCode: preferences.preferredAudioLanguageCode,
        variantLanguageCode: variant.audioLanguageCode,
      ),
      preferredSubtitleOrder: _preferredLanguageOrder(
        preferredLanguageCode: preferences.preferredSubtitleLanguageCode,
        variantLanguageCode: variant.subtitleLanguageCode,
      ),
      preferredQualityOrder: _preferredQualityOrder(
        preferredQualityRank: preferences.preferredQualityRank,
        variantQualityRank: variant.qualityRank,
      ),
      qualityOrder: -(variant.qualityRank ?? -1),
      sourceLabelOrder: variant.sourceLabel.toLowerCase(),
      titleOrder: variant.normalizedTitle.toLowerCase(),
      variantIdOrder: variant.id,
    );
  }

  final int preferredSourceOrder;
  final int preferredAudioOrder;
  final int preferredSubtitleOrder;
  final int preferredQualityOrder;
  final int qualityOrder;
  final String sourceLabelOrder;
  final String titleOrder;
  final String variantIdOrder;

  @override
  int compareTo(_PlaybackVariantRanking other) {
    final comparisons = <int>[
      preferredSourceOrder.compareTo(other.preferredSourceOrder),
      preferredAudioOrder.compareTo(other.preferredAudioOrder),
      preferredSubtitleOrder.compareTo(other.preferredSubtitleOrder),
      preferredQualityOrder.compareTo(other.preferredQualityOrder),
      qualityOrder.compareTo(other.qualityOrder),
      sourceLabelOrder.compareTo(other.sourceLabelOrder),
      titleOrder.compareTo(other.titleOrder),
      variantIdOrder.compareTo(other.variantIdOrder),
    ];

    for (final comparison in comparisons) {
      if (comparison != 0) {
        return comparison;
      }
    }

    return 0;
  }

  static int _preferredSourceOrder(
    String sourceId,
    Set<String> preferredSourceIds,
  ) {
    if (preferredSourceIds.isEmpty) {
      return 0;
    }

    return preferredSourceIds.contains(sourceId) ? 0 : 1;
  }

  static int _preferredLanguageOrder({
    required String? preferredLanguageCode,
    required String? variantLanguageCode,
  }) {
    final normalizedPreferred = _normalizeLanguageCode(preferredLanguageCode);
    if (normalizedPreferred == null) {
      return 0;
    }

    final normalizedVariant = _normalizeLanguageCode(variantLanguageCode);
    if (normalizedVariant == null) {
      return 1;
    }

    return normalizedPreferred == normalizedVariant ? 0 : 1;
  }

  static int _preferredQualityOrder({
    required int? preferredQualityRank,
    required int? variantQualityRank,
  }) {
    if (preferredQualityRank == null || variantQualityRank == null) {
      return 0;
    }

    return (preferredQualityRank - variantQualityRank).abs();
  }

  static String? _normalizeLanguageCode(String? languageCode) {
    final normalized = languageCode?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }
}
