import 'package:flutter/material.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';
import 'package:movi/src/features/player/domain/value_objects/track_info.dart';
import 'package:movi/l10n/app_localizations.dart';
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

    // Mobile: fixed to 75% of the safe available height.
    // Desktop: bounded height to avoid full-screen sheets.
    final maxSheetHeight = isMobile
        ? availableHeight * 0.75
        : (availableHeight * 0.7).clamp(420.0, 760.0);

    return _TrackSelectionSheetLayout(maxSheetHeight: maxSheetHeight);
  }
}

class _TrackSelectionSheetScaffold extends StatelessWidget {
  const _TrackSelectionSheetScaffold({
    required this.title,
    required this.list,
    this.headerAction,
  });

  final String title;
  final Widget list;
  final Widget? headerAction;

  @override
  Widget build(BuildContext context) {
    final layout = _TrackSelectionSheetLayout.fromContext(context);

    return SizedBox(
      height: layout.maxSheetHeight,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1F1F1F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    if (headerAction != null) headerAction!,
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF3A3A3A), height: 1),
              Expanded(child: list),
            ],
          ),
        ),
      ),
    );
  }
}

/// Menu de sélection des pistes de sous-titres
class SubtitleTrackSelectionMenu extends StatelessWidget {
  const SubtitleTrackSelectionMenu({
    super.key,
    required this.tracks,
    required this.currentTrack,
    required this.onTrackSelected,
    required this.onDisable,
    required this.onOpenSubtitleSettings,
  });

  final List<TrackInfo> tracks;
  final TrackInfo? currentTrack;
  final Future<void> Function(TrackInfo track) onTrackSelected;
  final Future<void> Function() onDisable;
  final VoidCallback onOpenSubtitleSettings;

  @override
  Widget build(BuildContext context) {
    return _TrackSelectionSheetScaffold(
      title: AppLocalizations.of(context)!.subtitlesMenuTitle,
      headerAction: IconButton(
        onPressed: onOpenSubtitleSettings,
        icon: const MoviAssetIcon(
          AppAssets.iconSettings,
          color: Colors.white,
          width: 20,
          height: 20,
        ),
      ),
      list: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: tracks.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isDisabled = currentTrack == null;
                  return _TrackOptionTile(
                    selected: isDisabled,
                    title: AppLocalizations.of(context)!.actionDisable,
                    onTap: () async {
                      await onDisable();
                      if (!context.mounted) return;
                      Navigator.of(context).pop(null);
                    },
                  );
                }

                final track = tracks[index - 1];
                final isSelected = currentTrack?.id == track.id;
                final label = TrackLabelFormatter.formatTrackLabel(track);
                final trackTitle = label.isNotEmpty
                    ? label
                    : AppLocalizations.of(
                        context,
                      )!.defaultTrackLabel(track.id.toString());

                return _TrackOptionTile(
                  selected: isSelected,
                  title: trackTitle,
                  subtitle: track.title != null && track.title!.isNotEmpty
                      ? track.title!
                      : null,
                  onTap: () async {
                    await onTrackSelected(track);
                    if (!context.mounted) return;
                    Navigator.of(context).pop(track);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Menu de sélection des pistes audio
class AudioTrackSelectionMenu extends StatelessWidget {
  const AudioTrackSelectionMenu({
    super.key,
    required this.tracks,
    required this.currentTrack,
    required this.onTrackSelected,
  });

  final List<TrackInfo> tracks;
  final TrackInfo? currentTrack;
  final Future<void> Function(TrackInfo track) onTrackSelected;

  @override
  Widget build(BuildContext context) {
    return _TrackSelectionSheetScaffold(
      title: AppLocalizations.of(context)!.audioMenuTitle,
      list: ListView.builder(
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          final isSelected = currentTrack?.id == track.id;
          final label = TrackLabelFormatter.formatTrackLabel(track);
          final trackTitle = label.isNotEmpty
              ? label
              : AppLocalizations.of(
                  context,
                )!.defaultTrackLabel(track.id.toString());

          return _TrackOptionTile(
            selected: isSelected,
            title: trackTitle,
            subtitle: track.title != null && track.title!.isNotEmpty
                ? track.title!
                : null,
            onTap: () async {
              await onTrackSelected(track);
              if (!context.mounted) return;
              Navigator.of(context).pop(track);
            },
          );
        },
      ),
    );
  }
}

class _TrackOptionTile extends StatelessWidget {
  const _TrackOptionTile({
    required this.selected,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final bool selected;
  final String title;
  final String? subtitle;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(10);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async => onTap(),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2A2A2A) : Colors.transparent,
            borderRadius: borderRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                          color: selected ? Colors.white : Colors.white70,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
