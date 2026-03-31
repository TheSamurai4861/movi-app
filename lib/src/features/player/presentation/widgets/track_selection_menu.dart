import 'package:flutter/material.dart';
import 'package:movi/src/features/player/domain/value_objects/track_info.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/features/player/presentation/utils/track_label_formatter.dart';

class _TrackSelectionSheetLayout {
  const _TrackSelectionSheetLayout({
    required this.maxSheetHeight,
    required this.maxListHeight,
  });

  final double maxSheetHeight;
  final double maxListHeight;

  static _TrackSelectionSheetLayout fromContext(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final isMobile = size.shortestSide < 600;

    // Mobile: sheet can grow up to 3/4 of screen height.
    final maxSheetHeight = isMobile ? size.height * 0.75 : double.infinity;

    // Desktop: cap list height to ~4 visible items, then scroll.
    const tileHeight = 56.0; // Typical ListTile height (1 line).
    final maxListHeight = isMobile ? double.infinity : tileHeight * 4;

    return _TrackSelectionSheetLayout(
      maxSheetHeight: maxSheetHeight,
      maxListHeight: maxListHeight,
    );
  }
}

class _TrackSelectionSheetScaffold extends StatelessWidget {
  const _TrackSelectionSheetScaffold({
    required this.title,
    required this.list,
  });

  final String title;
  final Widget list;

  @override
  Widget build(BuildContext context) {
    final layout = _TrackSelectionSheetLayout.fromContext(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: layout.maxSheetHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1F1F1F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF3A3A3A), height: 1),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: layout.maxListHeight),
                child: list,
              ),
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
  });

  final List<TrackInfo> tracks;
  final TrackInfo? currentTrack;
  final Future<void> Function(TrackInfo track) onTrackSelected;
  final Future<void> Function() onDisable;

  @override
  Widget build(BuildContext context) {
    return _TrackSelectionSheetScaffold(
      title: AppLocalizations.of(context)!.subtitlesMenuTitle,
      list: ListView.builder(
        shrinkWrap: true,
        itemCount: tracks.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            final isDisabled = currentTrack == null;
            return ListTile(
              leading: Icon(
                isDisabled
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isDisabled ? Colors.white : Colors.white70,
              ),
              title: Text(
                AppLocalizations.of(context)!.actionDisable,
                style: TextStyle(
                  color: isDisabled ? Colors.white : Colors.white70,
                  fontWeight: isDisabled ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isDisabled,
              selectedTileColor: const Color(0xFF2A2A2A),
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

          return ListTile(
            leading: Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? Colors.white : Colors.white70,
            ),
            title: Text(
              trackTitle,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: track.title != null && track.title!.isNotEmpty
                ? Text(
                    track.title!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  )
                : null,
            selected: isSelected,
            selectedTileColor: const Color(0xFF2A2A2A),
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
        shrinkWrap: true,
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

          return ListTile(
            leading: Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? Colors.white : Colors.white70,
            ),
            title: Text(
              trackTitle,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: track.title != null && track.title!.isNotEmpty
                ? Text(
                    track.title!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  )
                : null,
            selected: isSelected,
            selectedTileColor: const Color(0xFF2A2A2A),
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
