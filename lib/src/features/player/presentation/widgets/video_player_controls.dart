import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';

/// Widget de contrôles du player vidéo.
///
/// Implémentation TV-first : chaque contrôle critique a un FocusNode explicite,
/// un point d'entrée stable et des voisins directionnels simples.
class VideoPlayerControls extends ConsumerStatefulWidget {
  const VideoPlayerControls({
    super.key,
    required this.title,
    this.subtitle,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.hasSubtitles,
    required this.subtitlesEnabled,
    required this.onBack,
    required this.onPlayPause,
    required this.onSeekForward10,
    required this.onSeekForward30,
    required this.onSeekBackward10,
    required this.onSeekBackward30,
    required this.onSeek,
    required this.onToggleSubtitles,
    this.onAudio,
    this.onChromecast,
    this.onVideoFitMode,
    required this.formatDuration,
    this.hasAudioTracks = false,
    this.onRestart,
    this.onNextEpisode,
    this.isSeries = false,
    this.onPictureInPicture,
    this.isPipSupported = false,
    this.isPipActive = false,
    this.requestEntryFocus = true,
  });

  final String title;
  final String? subtitle;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final bool hasSubtitles;
  final bool subtitlesEnabled;
  final VoidCallback onBack;
  final VoidCallback onPlayPause;
  final VoidCallback onSeekForward10;
  final VoidCallback onSeekForward30;
  final VoidCallback onSeekBackward10;
  final VoidCallback onSeekBackward30;
  final void Function(double) onSeek;
  final VoidCallback onToggleSubtitles;
  final VoidCallback? onAudio;
  final VoidCallback? onChromecast;
  final VoidCallback? onVideoFitMode;
  final String Function(Duration) formatDuration;
  final bool hasAudioTracks;
  final VoidCallback? onRestart;
  final VoidCallback? onNextEpisode;
  final bool isSeries;
  final VoidCallback? onPictureInPicture;
  final bool isPipSupported;
  final bool isPipActive;
  final bool requestEntryFocus;

  @override
  ConsumerState<VideoPlayerControls> createState() =>
      _VideoPlayerControlsState();
}

class _VideoPlayerControlsState extends ConsumerState<VideoPlayerControls> {
  late final FocusNode _backFocusNode = FocusNode(debugLabel: 'player_back');
  late final FocusNode _resizeFocusNode = FocusNode(
    debugLabel: 'player_resize',
  );
  late final FocusNode _castFocusNode = FocusNode(debugLabel: 'player_cast');
  late final FocusNode _rewind30FocusNode = FocusNode(
    debugLabel: 'player_rewind_30',
  );
  late final FocusNode _rewind10FocusNode = FocusNode(
    debugLabel: 'player_rewind_10',
  );
  late final FocusNode _playPauseFocusNode = FocusNode(
    debugLabel: 'player_play_pause',
  );
  late final FocusNode _forward10FocusNode = FocusNode(
    debugLabel: 'player_forward_10',
  );
  late final FocusNode _forward30FocusNode = FocusNode(
    debugLabel: 'player_forward_30',
  );
  late final FocusNode _nextEpisodeFocusNode = FocusNode(
    debugLabel: 'player_next_episode',
  );
  late final FocusNode _restartFocusNode = FocusNode(
    debugLabel: 'player_restart',
  );
  late final FocusNode _audioFocusNode = FocusNode(debugLabel: 'player_audio');
  late final FocusNode _subtitleFocusNode = FocusNode(
    debugLabel: 'player_subtitle',
  );
  late final FocusNode _pipFocusNode = FocusNode(debugLabel: 'player_pip');

  FocusNode get _entryFocusNode => _playPauseFocusNode;

  @override
  void initState() {
    super.initState();
    if (widget.requestEntryFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_entryFocusNode.context != null &&
            _entryFocusNode.canRequestFocus) {
          _entryFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant VideoPlayerControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.requestEntryFocus && widget.requestEntryFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_entryFocusNode.context != null &&
            _entryFocusNode.canRequestFocus) {
          _entryFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _backFocusNode.dispose();
    _resizeFocusNode.dispose();
    _castFocusNode.dispose();
    _rewind30FocusNode.dispose();
    _rewind10FocusNode.dispose();
    _playPauseFocusNode.dispose();
    _forward10FocusNode.dispose();
    _forward30FocusNode.dispose();
    _nextEpisodeFocusNode.dispose();
    _restartFocusNode.dispose();
    _audioFocusNode.dispose();
    _subtitleFocusNode.dispose();
    _pipFocusNode.dispose();
    super.dispose();
  }

  String _getDisplayTitle() {
    if (!widget.isSeries) {
      return widget.title;
    }

    final parts = widget.title.split(' - ');
    if (parts.length >= 2) {
      final seriesTitle = parts[0].trim();
      for (var i = 1; i < parts.length; i++) {
        final regex = RegExp(r'S(\d{2})E(\d{2})');
        final match = regex.firstMatch(parts[i]);
        if (match != null) {
          final season = match.group(1);
          final episode = match.group(2);
          return 'S$season E$episode - $seriesTitle';
        }
      }
    }
    return widget.title;
  }

  List<FocusNode> get _topRowNodes {
    return [
      _backFocusNode,
      if (widget.onVideoFitMode != null) _resizeFocusNode,
      if (widget.onChromecast != null) _castFocusNode,
    ];
  }

  List<FocusNode> get _centerRowNodes => [
    _rewind30FocusNode,
    _rewind10FocusNode,
    _playPauseFocusNode,
    _forward10FocusNode,
    _forward30FocusNode,
  ];

  List<FocusNode> get _bottomRowNodes {
    return [
      if (widget.isSeries && widget.onNextEpisode != null)
        _nextEpisodeFocusNode,
      if (widget.onRestart != null) _restartFocusNode,
      if (widget.hasAudioTracks) _audioFocusNode,
      _subtitleFocusNode,
      if (widget.isPipSupported && widget.onPictureInPicture != null)
        _pipFocusNode,
    ];
  }

  KeyEventResult _handleRowKeyEvent({
    required KeyEvent event,
    required FocusNode currentNode,
    required List<FocusNode> rowNodes,
    List<FocusNode>? upRowNodes,
    List<FocusNode>? downRowNodes,
  }) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final currentIndex = rowNodes.indexOf(currentNode);
    if (currentIndex == -1) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft && currentIndex > 0) {
      rowNodes[currentIndex - 1].requestFocus();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
        currentIndex + 1 < rowNodes.length) {
      rowNodes[currentIndex + 1].requestFocus();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
        upRowNodes != null &&
        upRowNodes.isNotEmpty) {
      upRowNodes[(upRowNodes.length / 2).floor()].requestFocus();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
        downRowNodes != null &&
        downRowNodes.isNotEmpty) {
      downRowNodes[(downRowNodes.length / 2).floor()].requestFocus();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.duration.inMilliseconds == 0
        ? 0.0
        : widget.position.inMilliseconds / widget.duration.inMilliseconds;
    final accentColor = ref.watch(asp.currentAccentColorProvider);
    final topRowNodes = _topRowNodes;
    final centerRowNodes = _centerRowNodes;
    final bottomRowNodes = _bottomRowNodes;

    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF000000), Color(0x00000000)],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xFF000000)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Center(
                  child: Text(
                    _getDisplayTitle(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    _PlayerIconAction(
                      focusNode: _backFocusNode,
                      iconAsset: AppAssets.iconBack,
                      semanticLabel: AppLocalizations.of(context)!.actionBack,
                      onPressed: widget.onBack,
                      onKeyEvent: (event) => _handleRowKeyEvent(
                        event: event,
                        currentNode: _backFocusNode,
                        rowNodes: topRowNodes,
                        downRowNodes: centerRowNodes,
                      ),
                    ),
                    const Spacer(),
                    if (widget.onVideoFitMode != null)
                      _PlayerIconAction(
                        focusNode: _resizeFocusNode,
                        iconAsset: AppAssets.iconResize,
                        semanticLabel: AppLocalizations.of(
                          context,
                        )!.videoFitModeMenuTitle,
                        onPressed: widget.onVideoFitMode!,
                        onKeyEvent: (event) => _handleRowKeyEvent(
                          event: event,
                          currentNode: _resizeFocusNode,
                          rowNodes: topRowNodes,
                          downRowNodes: centerRowNodes,
                        ),
                      ),
                    if (widget.onVideoFitMode != null &&
                        widget.onChromecast != null)
                      const SizedBox(width: 24),
                    if (widget.onChromecast != null)
                      _PlayerIconAction(
                        focusNode: _castFocusNode,
                        iconAsset: AppAssets.iconChromecast,
                        semanticLabel: 'Chromecast',
                        onPressed: widget.onChromecast!,
                        onKeyEvent: (event) => _handleRowKeyEvent(
                          event: event,
                          currentNode: _castFocusNode,
                          rowNodes: topRowNodes,
                          downRowNodes: centerRowNodes,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PlayerIconAction(
                    focusNode: _rewind30FocusNode,
                    semanticLabel: AppLocalizations.of(
                      context,
                    )!.controlRewind30,
                    iconAsset: AppAssets.iconRewind,
                    label: AppLocalizations.of(context)!.controlRewind30,
                    onPressed: widget.onSeekBackward30,
                    onKeyEvent: (event) => _handleRowKeyEvent(
                      event: event,
                      currentNode: _rewind30FocusNode,
                      rowNodes: centerRowNodes,
                      upRowNodes: topRowNodes,
                      downRowNodes: bottomRowNodes,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _PlayerIconAction(
                    focusNode: _rewind10FocusNode,
                    semanticLabel: AppLocalizations.of(
                      context,
                    )!.controlRewind10,
                    iconAsset: AppAssets.iconRewind,
                    label: AppLocalizations.of(context)!.controlRewind10,
                    onPressed: widget.onSeekBackward10,
                    onKeyEvent: (event) => _handleRowKeyEvent(
                      event: event,
                      currentNode: _rewind10FocusNode,
                      rowNodes: centerRowNodes,
                      upRowNodes: topRowNodes,
                      downRowNodes: bottomRowNodes,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Transform.translate(
                    offset: const Offset(0, -6),
                    child: _PlayerIconAction(
                      focusNode: _playPauseFocusNode,
                      iconAsset: widget.isPlaying
                          ? AppAssets.iconPause
                          : AppAssets.iconPlay,
                      semanticLabel: widget.isPlaying ? 'Pause' : 'Play',
                      onPressed: widget.onPlayPause,
                      isLarge: true,
                      onKeyEvent: (event) => _handleRowKeyEvent(
                        event: event,
                        currentNode: _playPauseFocusNode,
                        rowNodes: centerRowNodes,
                        upRowNodes: topRowNodes,
                        downRowNodes: bottomRowNodes,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  _PlayerIconAction(
                    focusNode: _forward10FocusNode,
                    semanticLabel: AppLocalizations.of(
                      context,
                    )!.controlForward10,
                    iconAsset: AppAssets.iconForward,
                    label: AppLocalizations.of(context)!.controlForward10,
                    onPressed: widget.onSeekForward10,
                    onKeyEvent: (event) => _handleRowKeyEvent(
                      event: event,
                      currentNode: _forward10FocusNode,
                      rowNodes: centerRowNodes,
                      upRowNodes: topRowNodes,
                      downRowNodes: bottomRowNodes,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _PlayerIconAction(
                    focusNode: _forward30FocusNode,
                    semanticLabel: AppLocalizations.of(
                      context,
                    )!.controlForward30,
                    iconAsset: AppAssets.iconForward,
                    label: AppLocalizations.of(context)!.controlForward30,
                    onPressed: widget.onSeekForward30,
                    onKeyEvent: (event) => _handleRowKeyEvent(
                      event: event,
                      currentNode: _forward30FocusNode,
                      rowNodes: centerRowNodes,
                      upRowNodes: topRowNodes,
                      downRowNodes: bottomRowNodes,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12,
                          ),
                        ),
                        child: IgnorePointer(
                          child: Slider(
                            value: progress.clamp(0.0, 1.0),
                            onChanged: (_) {},
                            activeColor: accentColor,
                            inactiveColor: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            widget.formatDuration(widget.position),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            ' : ',
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                          Text(
                            widget.formatDuration(widget.duration),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          if (widget.isSeries && widget.onNextEpisode != null)
                            _PlayerTextAction(
                              focusNode: _nextEpisodeFocusNode,
                              label: AppLocalizations.of(
                                context,
                              )!.actionNextEpisode,
                              onPressed: widget.onNextEpisode!,
                              trailing: Transform.rotate(
                                angle: 3.14159,
                                child: const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: MoviAssetIcon(
                                    AppAssets.iconBack,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              onKeyEvent: (event) => _handleRowKeyEvent(
                                event: event,
                                currentNode: _nextEpisodeFocusNode,
                                rowNodes: bottomRowNodes,
                                upRowNodes: centerRowNodes,
                              ),
                            ),
                          if (widget.isSeries &&
                              widget.onNextEpisode != null &&
                              widget.onRestart != null)
                            const SizedBox(width: 24),
                          if (widget.onRestart != null)
                            _PlayerTextAction(
                              focusNode: _restartFocusNode,
                              label: AppLocalizations.of(
                                context,
                              )!.actionRestart,
                              trailing: const SizedBox(
                                width: 28,
                                height: 28,
                                child: MoviAssetIcon(
                                  AppAssets.iconRewind,
                                  color: Colors.white,
                                ),
                              ),
                              onPressed: widget.onRestart!,
                              onKeyEvent: (event) => _handleRowKeyEvent(
                                event: event,
                                currentNode: _restartFocusNode,
                                rowNodes: bottomRowNodes,
                                upRowNodes: centerRowNodes,
                              ),
                            ),
                          if (widget.onRestart != null)
                            const SizedBox(width: 36)
                          else if (widget.isSeries &&
                              widget.onNextEpisode != null)
                            const SizedBox(width: 36),
                          if (widget.hasAudioTracks)
                            _PlayerIconAction(
                              focusNode: _audioFocusNode,
                              iconAsset: AppAssets.iconAudio,
                              semanticLabel: AppLocalizations.of(
                                context,
                              )!.audioMenuTitle,
                              onPressed: widget.onAudio ?? () {},
                              onKeyEvent: (event) => _handleRowKeyEvent(
                                event: event,
                                currentNode: _audioFocusNode,
                                rowNodes: bottomRowNodes,
                                upRowNodes: centerRowNodes,
                              ),
                            ),
                          if (widget.hasAudioTracks) const SizedBox(width: 24),
                          _PlayerIconAction(
                            focusNode: _subtitleFocusNode,
                            iconAsset: widget.hasSubtitles
                                ? AppAssets.iconSubtitles
                                : AppAssets.iconSubtitlesDisabled,
                            semanticLabel: AppLocalizations.of(
                              context,
                            )!.subtitlesMenuTitle,
                            onPressed: widget.hasSubtitles
                                ? widget.onToggleSubtitles
                                : null,
                            onKeyEvent: (event) => _handleRowKeyEvent(
                              event: event,
                              currentNode: _subtitleFocusNode,
                              rowNodes: bottomRowNodes,
                              upRowNodes: centerRowNodes,
                            ),
                          ),
                          if (widget.isPipSupported &&
                              widget.onPictureInPicture != null) ...[
                            const SizedBox(width: 24),
                            _PlayerIconAction(
                              focusNode: _pipFocusNode,
                              icon: Icons.picture_in_picture,
                              iconColor: widget.isPipActive
                                  ? accentColor
                                  : Colors.white,
                              semanticLabel: 'Picture in picture',
                              onPressed: widget.onPictureInPicture!,
                              onKeyEvent: (event) => _handleRowKeyEvent(
                                event: event,
                                currentNode: _pipFocusNode,
                                rowNodes: bottomRowNodes,
                                upRowNodes: centerRowNodes,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerIconAction extends StatelessWidget {
  const _PlayerIconAction({
    required this.focusNode,
    required this.semanticLabel,
    required this.onPressed,
    required this.onKeyEvent,
    this.iconAsset,
    this.icon,
    this.label,
    this.isLarge = false,
    this.iconColor,
  }) : assert(iconAsset != null || icon != null);

  final FocusNode focusNode;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final KeyEventResult Function(KeyEvent event) onKeyEvent;
  final String? iconAsset;
  final IconData? icon;
  final String? label;
  final bool isLarge;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final buttonSize = isLarge ? 64.0 : 48.0;
    final iconSize = isLarge ? 32.0 : 24.0;
    final effectiveIconColor =
        iconColor ?? (onPressed == null ? Colors.white54 : Colors.white);

    return Focus(
      onKeyEvent: (_, event) => onKeyEvent(event),
      child: MoviFocusableAction(
        focusNode: focusNode,
        onPressed: onPressed,
        semanticLabel: semanticLabel,
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MoviFocusFrame(
                scale: state.focused ? 1.04 : 1,
                borderRadius: BorderRadius.circular(buttonSize / 2),
                backgroundColor: state.focused
                    ? Colors.white.withValues(alpha: 0.28)
                    : Colors.white.withValues(alpha: 0.20),
                borderColor: state.focused ? Colors.white : Colors.transparent,
                borderWidth: 2,
                padding: EdgeInsets.all(isLarge ? 16 : 12),
                child: SizedBox(
                  width: buttonSize - (isLarge ? 32 : 24),
                  height: buttonSize - (isLarge ? 32 : 24),
                  child: Center(
                    child: iconAsset != null
                        ? MoviAssetIcon(
                            iconAsset!,
                            width: iconSize,
                            height: iconSize,
                            color: effectiveIconColor,
                          )
                        : Icon(icon, size: iconSize, color: effectiveIconColor),
                  ),
                ),
              ),
              if (label != null && label!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  label!,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PlayerTextAction extends StatelessWidget {
  const _PlayerTextAction({
    required this.focusNode,
    required this.label,
    required this.onPressed,
    required this.onKeyEvent,
    this.trailing,
  });

  final FocusNode focusNode;
  final String label;
  final VoidCallback onPressed;
  final KeyEventResult Function(KeyEvent event) onKeyEvent;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (_, event) => onKeyEvent(event),
      child: MoviFocusableAction(
        focusNode: focusNode,
        onPressed: onPressed,
        semanticLabel: label,
        builder: (context, state) {
          return MoviFocusFrame(
            scale: state.focused ? 1.02 : 1,
            borderRadius: BorderRadius.circular(14),
            backgroundColor: state.focused
                ? Colors.white.withValues(alpha: 0.16)
                : Colors.transparent,
            borderColor: state.focused ? Colors.white : Colors.transparent,
            borderWidth: 2,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              ],
            ),
          );
        },
      ),
    );
  }
}
