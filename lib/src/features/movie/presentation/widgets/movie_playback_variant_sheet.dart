import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:movi/l10n/app_localizations.dart';
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
    FocusNode? triggerFocusNode,
  }) async {
    final effectiveTriggerFocusNode =
        triggerFocusNode ?? FocusManager.instance.primaryFocus;

    final selected = await showCupertinoModalPopup<PlaybackVariant>(
      context: context,
      builder: (sheetContext) =>
          MoviePlaybackVariantSheet(movieTitle: movieTitle, variants: variants),
    );

    if (selected == null &&
        effectiveTriggerFocusNode != null &&
        effectiveTriggerFocusNode.context != null &&
        effectiveTriggerFocusNode.canRequestFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (effectiveTriggerFocusNode.context != null &&
            effectiveTriggerFocusNode.canRequestFocus) {
          effectiveTriggerFocusNode.requestFocus();
        }
      });
    }

    return selected;
  }

  KeyEventResult _handleSheetKeyEvent(BuildContext context, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.goBack) {
      Navigator.of(context).pop<PlaybackVariant?>(null);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, event) => _handleSheetKeyEvent(context, event),
      child: CupertinoActionSheet(
        title: Text(movieTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        actions: List<Widget>.generate(variants.length, (index) {
          final variant = variants[index];
          final label = _buildVariantTitle(variant, index, l10n);
          return CupertinoActionSheetAction(
            key: Key('movie_variant_$index'),
            onPressed: () =>
                Navigator.of(context).pop<PlaybackVariant>(variant),
            child: Text(label, maxLines: 3, overflow: TextOverflow.ellipsis),
          );
        }),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop<PlaybackVariant?>(null),
          child: Text(l10n.actionCancel),
        ),
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
