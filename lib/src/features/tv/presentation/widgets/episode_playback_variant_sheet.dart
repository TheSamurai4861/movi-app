import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/core/widgets/movi_tv_action_menu.dart';
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
    FocusNode? triggerFocusNode,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final effectiveTriggerFocusNode =
        triggerFocusNode ?? FocusManager.instance.primaryFocus;

    final selected = await (_useDesktopTvModal(context)
        ? _showDesktopTvModal(
            context: context,
            episodeTitle: episodeTitle,
            variants: variants,
            l10n: l10n,
          )
        : showCupertinoModalPopup<PlaybackVariant>(
            context: context,
            builder: (sheetContext) => EpisodePlaybackVariantSheet(
              episodeTitle: episodeTitle,
              variants: variants,
            ),
          ));

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

  static Future<PlaybackVariant?> _showDesktopTvModal({
    required BuildContext context,
    required String episodeTitle,
    required List<PlaybackVariant> variants,
    required AppLocalizations l10n,
  }) async {
    PlaybackVariant? selected;
    await showMoviTvActionMenu(
      context: context,
      title: episodeTitle,
      cancelLabel: l10n.actionCancel,
      actions: List<MoviTvActionMenuAction>.generate(variants.length, (index) {
        final variant = variants[index];
        final label = _buildVariantTitleStatic(variant, index, l10n);
        return MoviTvActionMenuAction(
          label: label,
          onPressed: () {
            selected = variant;
          },
        );
      }),
    );
    return selected;
  }

  static bool _useDesktopTvModal(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenType = context.resolveScreenType(size.width, size.height);
    return screenType == ScreenType.desktop || screenType == ScreenType.tv;
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
      ),
    );
  }

  String _buildVariantTitle(
    PlaybackVariant variant,
    int index,
    AppLocalizations l10n,
  ) {
    return _buildVariantTitleStatic(variant, index, l10n);
  }

  static String _buildVariantTitleStatic(
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
