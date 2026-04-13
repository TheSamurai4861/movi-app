import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/movi_overlay_focus_scope.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/features/player/domain/value_objects/track_info.dart';
import 'package:movi/src/features/player/presentation/utils/track_label_formatter.dart';

class _TrackSelectionSheetLayout {
  const _TrackSelectionSheetLayout({required this.maxSheetHeight});

  final double maxSheetHeight;

  static _TrackSelectionSheetLayout fromContext(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final isMobile = size.shortestSide < 600;
    final safeTop = mediaQuery.padding.top;
    final safeBottom = mediaQuery.padding.bottom;
    final availableHeight = size.height - safeTop - safeBottom;

    final maxSheetHeight = isMobile
        ? availableHeight * 0.75
        : (availableHeight * 0.7).clamp(420.0, 760.0);

    return _TrackSelectionSheetLayout(maxSheetHeight: maxSheetHeight);
  }
}

class _TrackSelectionSheetScaffold extends StatefulWidget {
  const _TrackSelectionSheetScaffold({
    required this.title,
    required this.children,
    this.headerAction,
    this.triggerFocusNode,
    this.initialFocusNode,
    this.originRegionId,
    this.fallbackRegionId,
    this.overlayRegionId = AppFocusRegionId.dialogPrimary,
  });

  final String title;
  final List<Widget> children;
  final Widget? headerAction;
  final FocusNode? triggerFocusNode;
  final FocusNode? initialFocusNode;
  final AppFocusRegionId? originRegionId;
  final AppFocusRegionId? fallbackRegionId;
  final AppFocusRegionId overlayRegionId;

  @override
  State<_TrackSelectionSheetScaffold> createState() =>
      _TrackSelectionSheetScaffoldState();
}

class _TrackSelectionSheetScaffoldState
    extends State<_TrackSelectionSheetScaffold> {
  late final FocusNode _closeFocusNode = FocusNode(
    debugLabel: 'track_menu_close',
  );

  @override
  void dispose() {
    _closeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = _TrackSelectionSheetLayout.fromContext(context);

    return MoviOverlayFocusScope(
      triggerFocusNode: widget.triggerFocusNode,
      originRegionId: widget.originRegionId,
      overlayRegionId: widget.overlayRegionId,
      fallbackRegionId: widget.fallbackRegionId,
      initialFocusNode: widget.initialFocusNode ?? _closeFocusNode,
      fallbackFocusNode: _closeFocusNode,
      debugLabel: 'TrackSelectionSheet',
      child: Container(
        constraints: BoxConstraints(maxHeight: layout.maxSheetHeight),
        decoration: const BoxDecoration(
          color: Color(0xFF1F1F1F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (widget.headerAction != null) ...[
                      widget.headerAction!,
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      focusNode: _closeFocusNode,
                      autofocus: false,
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF3A3A3A), height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: widget.children,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SubtitleTrackSelectionMenu extends StatefulWidget {
  const SubtitleTrackSelectionMenu({
    super.key,
    required this.tracks,
    required this.currentTrack,
    required this.onTrackSelected,
    required this.onDisable,
    required this.onOpenSubtitleSettings,
    this.triggerFocusNode,
    this.originRegionId,
    this.fallbackRegionId,
    this.overlayRegionId = AppFocusRegionId.dialogPrimary,
  });

  final List<TrackInfo> tracks;
  final TrackInfo? currentTrack;
  final Future<void> Function(TrackInfo track) onTrackSelected;
  final Future<void> Function() onDisable;
  final VoidCallback onOpenSubtitleSettings;
  final FocusNode? triggerFocusNode;
  final AppFocusRegionId? originRegionId;
  final AppFocusRegionId? fallbackRegionId;
  final AppFocusRegionId overlayRegionId;

  @override
  State<SubtitleTrackSelectionMenu> createState() =>
      _SubtitleTrackSelectionMenuState();
}

class _SubtitleTrackSelectionMenuState
    extends State<SubtitleTrackSelectionMenu> {
  late final List<FocusNode> _optionFocusNodes = List<FocusNode>.generate(
    widget.tracks.length + 1,
    (index) => FocusNode(debugLabel: 'subtitle_option_$index'),
  );

  @override
  void dispose() {
    for (final node in _optionFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      _TrackOptionTile(
        focusNode: _optionFocusNodes[0],
        previousFocusNode: null,
        nextFocusNode: _optionFocusNodes.length > 1
            ? _optionFocusNodes[1]
            : null,
        selected: widget.currentTrack == null,
        title: AppLocalizations.of(context)!.actionDisable,
        onTap: () async {
          await widget.onDisable();
          if (!context.mounted) return;
          Navigator.of(context).pop(null);
        },
      ),
    ];

    for (var i = 0; i < widget.tracks.length; i++) {
      final track = widget.tracks[i];
      final label = TrackLabelFormatter.formatTrackLabel(track);
      final trackTitle = label.isNotEmpty
          ? label
          : AppLocalizations.of(
              context,
            )!.defaultTrackLabel(track.id.toString());
      children.add(
        _TrackOptionTile(
          focusNode: _optionFocusNodes[i + 1],
          previousFocusNode: _optionFocusNodes[i],
          nextFocusNode: i + 2 < _optionFocusNodes.length
              ? _optionFocusNodes[i + 2]
              : null,
          selected: widget.currentTrack?.id == track.id,
          title: trackTitle,
          subtitle: track.title != null && track.title!.isNotEmpty
              ? track.title!
              : null,
          onTap: () async {
            await widget.onTrackSelected(track);
            if (!context.mounted) return;
            Navigator.of(context).pop(track);
          },
        ),
      );
    }

    return _TrackSelectionSheetScaffold(
      title: AppLocalizations.of(context)!.subtitlesMenuTitle,
      triggerFocusNode: widget.triggerFocusNode,
      originRegionId: widget.originRegionId,
      fallbackRegionId: widget.fallbackRegionId,
      overlayRegionId: widget.overlayRegionId,
      headerAction: IconButton(
        onPressed: widget.onOpenSubtitleSettings,
        icon: const MoviAssetIcon(
          AppAssets.iconSettings,
          color: Colors.white,
          width: 20,
          height: 20,
        ),
      ),
      initialFocusNode: _optionFocusNodes.first,
      children: children,
    );
  }
}

class AudioTrackSelectionMenu extends StatefulWidget {
  const AudioTrackSelectionMenu({
    super.key,
    required this.tracks,
    required this.currentTrack,
    required this.onTrackSelected,
    this.triggerFocusNode,
    this.originRegionId,
    this.fallbackRegionId,
    this.overlayRegionId = AppFocusRegionId.dialogPrimary,
  });

  final List<TrackInfo> tracks;
  final TrackInfo? currentTrack;
  final Future<void> Function(TrackInfo track) onTrackSelected;
  final FocusNode? triggerFocusNode;
  final AppFocusRegionId? originRegionId;
  final AppFocusRegionId? fallbackRegionId;
  final AppFocusRegionId overlayRegionId;

  @override
  State<AudioTrackSelectionMenu> createState() =>
      _AudioTrackSelectionMenuState();
}

class _AudioTrackSelectionMenuState extends State<AudioTrackSelectionMenu> {
  late final List<FocusNode> _optionFocusNodes = List<FocusNode>.generate(
    widget.tracks.length,
    (index) => FocusNode(debugLabel: 'audio_option_$index'),
  );

  @override
  void dispose() {
    for (final node in _optionFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < widget.tracks.length; i++) {
      final track = widget.tracks[i];
      final label = TrackLabelFormatter.formatTrackLabel(track);
      final trackTitle = label.isNotEmpty
          ? label
          : AppLocalizations.of(
              context,
            )!.defaultTrackLabel(track.id.toString());
      children.add(
        _TrackOptionTile(
          focusNode: _optionFocusNodes[i],
          previousFocusNode: i > 0 ? _optionFocusNodes[i - 1] : null,
          nextFocusNode: i + 1 < _optionFocusNodes.length
              ? _optionFocusNodes[i + 1]
              : null,
          selected: widget.currentTrack?.id == track.id,
          title: trackTitle,
          subtitle: track.title != null && track.title!.isNotEmpty
              ? track.title!
              : null,
          onTap: () async {
            await widget.onTrackSelected(track);
            if (!context.mounted) return;
            Navigator.of(context).pop(track);
          },
        ),
      );
    }

    return _TrackSelectionSheetScaffold(
      title: AppLocalizations.of(context)!.audioMenuTitle,
      triggerFocusNode: widget.triggerFocusNode,
      originRegionId: widget.originRegionId,
      fallbackRegionId: widget.fallbackRegionId,
      overlayRegionId: widget.overlayRegionId,
      initialFocusNode: _optionFocusNodes.isNotEmpty
          ? _optionFocusNodes.first
          : null,
      children: children,
    );
  }
}

class _TrackOptionTile extends StatelessWidget {
  const _TrackOptionTile({
    required this.focusNode,
    required this.selected,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.previousFocusNode,
    this.nextFocusNode,
  });

  final FocusNode focusNode;
  final FocusNode? previousFocusNode;
  final FocusNode? nextFocusNode;
  final bool selected;
  final String title;
  final String? subtitle;
  final Future<void> Function() onTap;

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
        previousFocusNode != null &&
        previousFocusNode!.context != null) {
      previousFocusNode!.requestFocus();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
        nextFocusNode != null &&
        nextFocusNode!.context != null) {
      nextFocusNode!.requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(10);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Focus(
        onKeyEvent: (_, event) => _handleKeyEvent(event),
        child: MoviFocusableAction(
          focusNode: focusNode,
          onPressed: () async => onTap(),
          semanticLabel: title,
          builder: (context, state) {
            final isActive = selected || state.focused;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF2A2A2A) : Colors.transparent,
                borderRadius: borderRadius,
                border: state.focused
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: selected ? Colors.white : Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                          if (subtitle != null &&
                              subtitle!.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
