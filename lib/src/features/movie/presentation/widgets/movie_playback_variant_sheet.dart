import 'package:flutter/material.dart';
import 'package:movi/src/features/movie/presentation/utils/movie_playback_variant_descriptor_builder.dart';
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';

class MoviePlaybackVariantSheet extends StatelessWidget {
  const MoviePlaybackVariantSheet({
    super.key,
    required this.movieTitle,
    required this.variants,
  });

  final String movieTitle;
  final List<PlaybackVariant> variants;

  static Future<PlaybackVariant?> show(
    BuildContext context, {
    required String movieTitle,
    required List<PlaybackVariant> variants,
  }) {
    return showModalBottomSheet<PlaybackVariant>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) =>
          MoviePlaybackVariantSheet(movieTitle: movieTitle, variants: variants),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleLarge;
    final accentColor = theme.colorScheme.primary;
    final descriptors = const MoviePlaybackVariantDescriptorBuilder().build(
      variants,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            movieTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: titleStyle,
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: variants.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final variant = variants[index];
                final descriptor = descriptors[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).pop(variant),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          descriptor.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (descriptor.tags.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: descriptor.tags
                                .map(
                                  (tag) => _VariantTag(
                                    label: tag,
                                    accentColor: accentColor,
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VariantTag extends StatelessWidget {
  const _VariantTag({required this.label, required this.accentColor});

  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
