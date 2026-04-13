import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/movi_overlay_focus_scope.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/features/player/domain/value_objects/video_fit_mode.dart';

/// Menu de sélection du mode d'affichage vidéo.
class VideoFitModeSelectionMenu extends StatefulWidget {
  const VideoFitModeSelectionMenu({
    super.key,
    required this.currentMode,
    required this.onModeSelected,
    this.triggerFocusNode,
    this.originRegionId,
    this.fallbackRegionId,
    this.overlayRegionId = AppFocusRegionId.dialogPrimary,
  });

  final VideoFitMode currentMode;
  final Future<void> Function(VideoFitMode mode) onModeSelected;
  final FocusNode? triggerFocusNode;
  final AppFocusRegionId? originRegionId;
  final AppFocusRegionId? fallbackRegionId;
  final AppFocusRegionId overlayRegionId;

  @override
  State<VideoFitModeSelectionMenu> createState() =>
      _VideoFitModeSelectionMenuState();
}

class _VideoFitModeSelectionMenuState extends State<VideoFitModeSelectionMenu> {
  late final FocusNode _containFocusNode = FocusNode(
    debugLabel: 'video_fit_contain',
  );
  late final FocusNode _coverFocusNode = FocusNode(
    debugLabel: 'video_fit_cover',
  );
  late final FocusNode _closeFocusNode = FocusNode(
    debugLabel: 'video_fit_close',
  );

  @override
  void dispose() {
    _containFocusNode.dispose();
    _coverFocusNode.dispose();
    _closeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MoviOverlayFocusScope(
      triggerFocusNode: widget.triggerFocusNode,
      originRegionId: widget.originRegionId,
      overlayRegionId: widget.overlayRegionId,
      fallbackRegionId: widget.fallbackRegionId,
      initialFocusNode: widget.currentMode == VideoFitMode.cover
          ? _coverFocusNode
          : _containFocusNode,
      fallbackFocusNode: _closeFocusNode,
      debugLabel: 'VideoFitModeSelectionMenu',
      child: Container(
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
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.videoFitModeMenuTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      focusNode: _closeFocusNode,
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
                  children: [
                    _VideoFitModeOptionTile(
                      focusNode: _containFocusNode,
                      previousFocusNode: null,
                      nextFocusNode: _coverFocusNode,
                      selected: widget.currentMode == VideoFitMode.contain,
                      title: AppLocalizations.of(context)!.videoFitModeContain,
                      onTap: () async {
                        await widget.onModeSelected(VideoFitMode.contain);
                        if (!context.mounted) return;
                        Navigator.of(context).pop(VideoFitMode.contain);
                      },
                    ),
                    _VideoFitModeOptionTile(
                      focusNode: _coverFocusNode,
                      previousFocusNode: _containFocusNode,
                      nextFocusNode: null,
                      selected: widget.currentMode == VideoFitMode.cover,
                      title: AppLocalizations.of(context)!.videoFitModeCover,
                      onTap: () async {
                        await widget.onModeSelected(VideoFitMode.cover);
                        if (!context.mounted) return;
                        Navigator.of(context).pop(VideoFitMode.cover);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoFitModeOptionTile extends StatelessWidget {
  const _VideoFitModeOptionTile({
    required this.focusNode,
    required this.selected,
    required this.title,
    required this.onTap,
    this.previousFocusNode,
    this.nextFocusNode,
  });

  final FocusNode focusNode;
  final FocusNode? previousFocusNode;
  final FocusNode? nextFocusNode;
  final bool selected;
  final String title;
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
    return Focus(
      onKeyEvent: (_, event) => _handleKeyEvent(event),
      child: MoviFocusableAction(
        focusNode: focusNode,
        onPressed: () async => onTap(),
        semanticLabel: title,
        builder: (context, state) {
          final isActive = selected || state.focused;
          return MoviFocusFrame(
            borderRadius: BorderRadius.circular(12),
            backgroundColor: isActive
                ? const Color(0xFF2A2A2A)
                : Colors.transparent,
            borderColor: state.focused ? Colors.white : Colors.transparent,
            borderWidth: 2,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? Colors.white : Colors.white70,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white70,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
