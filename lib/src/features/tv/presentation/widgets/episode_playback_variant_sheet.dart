import 'package:flutter/cupertino.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';

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
    return showCupertinoModalPopup<PlaybackVariant>(
      context: context,
      builder: (sheetContext) => EpisodePlaybackVariantSheet(
        episodeTitle: episodeTitle,
        variants: variants,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CupertinoActionSheet(
      title: Text(episodeTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      actions: List<Widget>.generate(variants.length, (index) {
        final variant = variants[index];
        final label = _buildVariantTitle(variant, index, l10n);
        return CupertinoActionSheetAction(
          key: Key('episode_variant_$index'),
          onPressed: () => Navigator.of(context).pop<PlaybackVariant>(variant),
          child: Text(label, maxLines: 3, overflow: TextOverflow.ellipsis),
        );
      }),
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.of(context).pop<PlaybackVariant?>(null),
        child: Text(l10n.actionCancel),
      ),
    );
  }

  String _buildVariantTitle(
    PlaybackVariant variant,
    int index,
    AppLocalizations l10n,
  ) {
    final rawTitle = variant.rawTitle.trim();
    if (rawTitle.isNotEmpty) {
      return rawTitle;
    }

    final sourceLabel = variant.sourceLabel.trim();
    if (sourceLabel.isNotEmpty) {
      return sourceLabel;
    }

    return l10n.playbackVariantFallbackLabel(index + 1);
  }
}
