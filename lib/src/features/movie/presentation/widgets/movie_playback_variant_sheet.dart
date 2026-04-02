import 'package:flutter/material.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';

class MoviePlaybackVariantSheet extends StatelessWidget {
  const MoviePlaybackVariantSheet({
    super.key,
    required this.movieTitle,
    required this.variants,
    this.navigator,
  });

  final String movieTitle;
  final List<PlaybackVariant> variants;
  final NavigatorState? navigator;

  static Future<PlaybackVariant?> show(
    BuildContext context, {
    required String movieTitle,
    required List<PlaybackVariant> variants,
  }) {
    return showModalBottomSheet<PlaybackVariant>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      sheetAnimationStyle: AnimationStyle.noAnimation,
      builder: (sheetContext) => MoviePlaybackVariantSheet(
        movieTitle: movieTitle,
        variants: variants,
        navigator: Navigator.of(sheetContext),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleLarge;
    final l10n = AppLocalizations.of(context)!;
    final nav = navigator ?? Navigator.of(context);

    Widget buildVariantTile(int index) {
      final variant = variants[index];
      final label = _buildVariantTitle(variant, index, l10n);
      return SizedBox(
        height: 72,
        width: double.infinity,
        child: TextButton(
          key: Key('movie_variant_$index'),
          onPressed: () {
            nav.pop<PlaybackVariant>(variant);
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),
            child: MoviFocusFrame(
              // Keep the same visuals as before, but without relying on focus state.
              scale: 1,
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(20),
              backgroundColor: Colors.transparent,
              borderColor: Colors.white.withValues(alpha: 0.10),
              borderWidth: 1,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    }

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
          if (variants.length <= 3)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int index = 0; index < variants.length; index++) ...[
                  buildVariantTile(index),
                  if (index < variants.length - 1) const Divider(height: 1),
                ],
              ],
            )
          else
            SizedBox(
              height: 200,
              child: ListView.separated(
                itemCount: variants.length,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) => buildVariantTile(index),
              ),
            ),
        ],
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
