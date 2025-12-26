import 'package:flutter/material.dart';
import 'package:movi/src/features/player/domain/value_objects/track_info.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/features/player/presentation/utils/track_label_formatter.dart';

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
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1F1F1F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.subtitlesMenuTitle,
                    style: TextStyle(
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
            // Liste des pistes
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: tracks.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // Option "Désactiver"
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
                          fontWeight:
                              isDisabled ? FontWeight.w600 : FontWeight.normal,
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

                  // Formater le titre de la piste
                  final label = TrackLabelFormatter.formatTrackLabel(track);
                  final trackTitle = label.isNotEmpty
                      ? label
                      : AppLocalizations.of(context)!
                          .defaultTrackLabel(track.id.toString());

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
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
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
            ),
          ],
        ),
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
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1F1F1F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.audioMenuTitle,
                    style: TextStyle(
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
            // Liste des pistes
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  final isSelected = currentTrack?.id == track.id;

                  // Formater le titre de la piste
                  final label = TrackLabelFormatter.formatTrackLabel(track);
                  final trackTitle = label.isNotEmpty
                      ? label
                      : AppLocalizations.of(context)!
                          .defaultTrackLabel(track.id.toString());

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
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
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
            ),
          ],
        ),
      ),
    );
  }

  
}
