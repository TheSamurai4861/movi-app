import 'package:flutter/material.dart';
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
                          _buildVariantTitle(variant, index),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  String _buildVariantTitle(PlaybackVariant variant, int index) {
    final rawTitle = variant.rawTitle.trim();
    if (rawTitle.isNotEmpty) {
      return rawTitle;
    }

    final sourceLabel = variant.sourceLabel.trim();
    if (sourceLabel.isNotEmpty) {
      return sourceLabel;
    }

    return 'Version ${index + 1}';
  }
}
