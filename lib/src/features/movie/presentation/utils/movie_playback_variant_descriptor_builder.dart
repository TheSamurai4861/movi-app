import 'package:movi/src/features/movie/presentation/models/movie_playback_variant_descriptor.dart';
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';

class MoviePlaybackVariantDescriptorBuilder {
  const MoviePlaybackVariantDescriptorBuilder();

  List<MoviePlaybackVariantDescriptor> build(List<PlaybackVariant> variants) {
    final showQuality = _hasUsefulDifference(
      variants.map((variant) => _normalizedLabel(variant.qualityLabel)),
    );
    final showDynamicRange = _hasUsefulDifference(
      variants.map((variant) => _normalizedLabel(variant.dynamicRangeLabel)),
    );
    final showAudio = _hasUsefulDifference(
      variants.map((variant) => _normalizedLabel(variant.audioLanguageLabel)),
    );
    final showSubtitles = _hasUsefulDifference(
      variants.map((variant) => _subtitleTag(variant)),
    );

    final tagsByIndex = <int, List<String>>{
      for (var index = 0; index < variants.length; index++)
        index: _buildTags(
          variants[index],
          showQuality: showQuality,
          showDynamicRange: showDynamicRange,
          showAudio: showAudio,
          showSubtitles: showSubtitles,
        ),
    };

    _appendSourceWhenHelpful(variants, tagsByIndex);

    return List<MoviePlaybackVariantDescriptor>.generate(variants.length, (
      index,
    ) {
      final variant = variants[index];
      final tags = tagsByIndex[index]!;
      return MoviePlaybackVariantDescriptor(
        title: _buildTitle(
          variant,
          tags: tags,
          position: index,
          variants: variants,
          tagsByIndex: tagsByIndex,
        ),
        tags: List<String>.unmodifiable(tags),
      );
    }, growable: false);
  }

  List<String> _buildTags(
    PlaybackVariant variant, {
    required bool showQuality,
    required bool showDynamicRange,
    required bool showAudio,
    required bool showSubtitles,
  }) {
    return <String>[
      if (showQuality && _hasText(variant.qualityLabel))
        variant.qualityLabel!.trim(),
      if (showDynamicRange && _hasText(variant.dynamicRangeLabel))
        variant.dynamicRangeLabel!.trim(),
      if (showAudio && _hasText(variant.audioLanguageLabel))
        variant.audioLanguageLabel!.trim(),
      if (showSubtitles) ..._buildSubtitleTags(variant),
    ];
  }

  List<String> _buildSubtitleTags(PlaybackVariant variant) {
    if (_hasText(variant.subtitleLanguageLabel)) {
      return <String>['ST ${variant.subtitleLanguageLabel!.trim()}'];
    }
    if (variant.hasSubtitles == true) {
      return const <String>['ST'];
    }
    return const <String>[];
  }

  void _appendSourceWhenHelpful(
    List<PlaybackVariant> variants,
    Map<int, List<String>> tagsByIndex,
  ) {
    final groupedIndexes = <String, List<int>>{};
    for (var index = 0; index < variants.length; index++) {
      final signature = _signature(tagsByIndex[index]!);
      groupedIndexes.putIfAbsent(signature, () => <int>[]).add(index);
    }

    for (final indexes in groupedIndexes.values) {
      if (indexes.length < 2) {
        continue;
      }
      final distinctSources = indexes
          .map((index) => variants[index].sourceLabel.trim())
          .where((label) => label.isNotEmpty)
          .toSet();
      if (distinctSources.length < 2) {
        continue;
      }
      for (final index in indexes) {
        final sourceLabel = variants[index].sourceLabel.trim();
        if (sourceLabel.isEmpty) {
          continue;
        }
        tagsByIndex[index] = <String>[...tagsByIndex[index]!, sourceLabel];
      }
    }
  }

  String _buildTitle(
    PlaybackVariant variant, {
    required List<String> tags,
    required int position,
    required List<PlaybackVariant> variants,
    required Map<int, List<String>> tagsByIndex,
  }) {
    if (tags.isNotEmpty) {
      return 'Version ${position + 1}';
    }

    final sourceLabel = variant.sourceLabel.trim();
    if (sourceLabel.isEmpty) {
      return 'Version ${position + 1}';
    }

    final sameSourceCount = variants.indexed
        .where((entry) => entry.$2.sourceLabel.trim() == sourceLabel)
        .where((entry) => tagsByIndex[entry.$1]!.isEmpty)
        .length;

    if (sameSourceCount == 1) {
      return sourceLabel;
    }

    return 'Version ${position + 1}';
  }

  bool _hasUsefulDifference(Iterable<String?> values) {
    final distinctValues = values.toSet();
    return distinctValues.length > 1;
  }

  String? _subtitleTag(PlaybackVariant variant) {
    if (_hasText(variant.subtitleLanguageLabel)) {
      return 'ST ${variant.subtitleLanguageLabel!.trim()}';
    }
    if (variant.hasSubtitles == true) {
      return 'ST';
    }
    return null;
  }

  String _signature(List<String> tags) => tags.join('|');

  String? _normalizedLabel(String? value) {
    if (!_hasText(value)) {
      return null;
    }
    return value!.trim();
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
}
