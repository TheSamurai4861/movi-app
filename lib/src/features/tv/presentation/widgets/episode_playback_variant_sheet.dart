import 'package:flutter/material.dart';
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';

class EpisodePlaybackVariantSheet extends StatelessWidget {
  const EpisodePlaybackVariantSheet({
    super.key,
    required this.episodeTitle,
    required this.variants,
  });

  final String episodeTitle;
  final List<PlaybackVariant> variants;

  static Future<PlaybackVariant?> show(
    BuildContext context, {
    required String episodeTitle,
    required List<PlaybackVariant> variants,
  }) {
    return showModalBottomSheet<PlaybackVariant>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => EpisodePlaybackVariantSheet(
        episodeTitle: episodeTitle,
        variants: variants,
      ),
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
            episodeTitle,
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
                final label = _buildVariantTitle(variant, index);
                return MoviFocusableAction(
                  autofocus: index == 0,
                  semanticLabel: label,
                  onPressed: () => Navigator.of(context).pop(variant),
                  builder: (context, state) {
                    return MoviFocusFrame(
                      scale: state.focused ? 1.01 : 1,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      backgroundColor: state.focused
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.transparent,
                      borderColor: state.focused
                          ? Colors.white.withValues(alpha: 0.55)
                          : Colors.white.withValues(alpha: 0.10),
                      borderWidth: state.focused ? 2 : 1,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
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

