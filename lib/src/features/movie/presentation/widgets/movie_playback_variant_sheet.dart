import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/focus/movi_overlay_focus_scope.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';

class MoviePlaybackVariantSheet extends StatefulWidget {
  const MoviePlaybackVariantSheet({
    super.key,
    required this.movieTitle,
    required this.variants,
    this.navigator,
    this.triggerFocusNode,
  });

  final String movieTitle;
  final List<PlaybackVariant> variants;
  final NavigatorState? navigator;
  final FocusNode? triggerFocusNode;

  static Future<PlaybackVariant?> show(
    BuildContext context, {
    required String movieTitle,
    required List<PlaybackVariant> variants,
    FocusNode? triggerFocusNode,
  }) {
    final effectiveTriggerFocusNode =
        triggerFocusNode ?? FocusManager.instance.primaryFocus;
    return showDialog<PlaybackVariant>(
      context: context,
      barrierDismissible: true,
      builder: (sheetContext) => MoviePlaybackVariantSheet(
        movieTitle: movieTitle,
        variants: variants,
        navigator: Navigator.of(sheetContext),
        triggerFocusNode: effectiveTriggerFocusNode,
      ),
    );
  }

  @override
  State<MoviePlaybackVariantSheet> createState() =>
      _MoviePlaybackVariantSheetState();
}

class _MoviePlaybackVariantSheetState extends State<MoviePlaybackVariantSheet> {
  late final List<FocusNode> _variantFocusNodes = List<FocusNode>.generate(
    widget.variants.length,
    (index) => FocusNode(debugLabel: 'movie_playback_variant_$index'),
  );
  late final FocusNode _cancelFocusNode = FocusNode(
    debugLabel: 'movie_playback_variant_cancel',
  );

  @override
  void dispose() {
    for (final node in _variantFocusNodes) {
      node.dispose();
    }
    _cancelFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleSheetKeyEvent(KeyEvent event, NavigatorState nav) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.goBack) {
      nav.pop<PlaybackVariant?>(null);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final titleStyle = theme.textTheme.titleLarge;
    final l10n = AppLocalizations.of(context)!;
    final nav = widget.navigator ?? Navigator.of(context);

    Widget buildVariantTile(int index) {
      final variant = widget.variants[index];
      final label = _buildVariantTitle(variant, index, l10n);
      return _VariantMenuTile(
        key: Key('movie_variant_$index'),
        label: label,
        focusNode: _variantFocusNodes[index],
        previousFocusNode: index > 0 ? _variantFocusNodes[index - 1] : null,
        nextFocusNode: index < _variantFocusNodes.length - 1
            ? _variantFocusNodes[index + 1]
            : _cancelFocusNode,
        onTap: () => nav.pop<PlaybackVariant>(variant),
      );
    }

    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, event) => _handleSheetKeyEvent(event, nav),
      child: MoviOverlayFocusScope(
        triggerFocusNode: widget.triggerFocusNode,
        initialFocusNode: _variantFocusNodes.isNotEmpty
            ? _variantFocusNodes.first
            : _cancelFocusNode,
        fallbackFocusNode: _cancelFocusNode,
        debugLabel: 'MoviePlaybackVariantSheet',
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 32,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.movieTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: titleStyle?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 18),
                    if (widget.variants.length <= 3)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (
                            int index = 0;
                            index < widget.variants.length;
                            index++
                          ) ...[
                            buildVariantTile(index),
                            if (index < widget.variants.length - 1)
                              const SizedBox(height: 8),
                          ],
                        ],
                      )
                    else
                      SizedBox(
                        height: 240,
                        child: ListView.separated(
                          itemCount: widget.variants.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, index) => buildVariantTile(index),
                        ),
                      ),
                    const SizedBox(height: 14),
                    _VariantMenuTile(
                      label: l10n.actionCancel,
                      focusNode: _cancelFocusNode,
                      previousFocusNode: _variantFocusNodes.isNotEmpty
                          ? _variantFocusNodes.last
                          : null,
                      isCancel: true,
                      onTap: () => nav.pop<PlaybackVariant?>(null),
                    ),
                  ],
                ),
              ),
            ),
          ),
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

class _VariantMenuTile extends StatelessWidget {
  const _VariantMenuTile({
    super.key,
    required this.label,
    required this.focusNode,
    required this.onTap,
    this.previousFocusNode,
    this.nextFocusNode,
    this.isCancel = false,
  });

  final String label;
  final FocusNode focusNode;
  final FocusNode? previousFocusNode;
  final FocusNode? nextFocusNode;
  final bool isCancel;
  final VoidCallback onTap;

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (previousFocusNode != null &&
          previousFocusNode!.context != null &&
          previousFocusNode!.canRequestFocus) {
        previousFocusNode!.requestFocus();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (nextFocusNode != null &&
          nextFocusNode!.context != null &&
          nextFocusNode!.canRequestFocus) {
        nextFocusNode!.requestFocus();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Focus(
      onKeyEvent: (_, event) => _handleKeyEvent(event),
      child: SizedBox(
        height: 72,
        width: double.infinity,
        child: MoviFocusableAction(
          focusNode: focusNode,
          onPressed: onTap,
          semanticLabel: label,
          builder: (context, state) {
            final borderColor = isCancel
                ? colorScheme.error.withValues(alpha: state.focused ? 1 : 0.8)
                : colorScheme.primary.withValues(alpha: state.focused ? 1 : 0.45);
            final foreground = isCancel
                ? colorScheme.error
                : colorScheme.onSurface;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: MoviFocusFrame(
                scale: state.focused ? 1.02 : 1,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(20),
                backgroundColor: state.focused
                    ? colorScheme.primary.withValues(alpha: 0.16)
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                borderColor: borderColor,
                borderWidth: 2,
                alignment: Alignment.center,
                child: Text(
                  label,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
