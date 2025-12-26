import 'package:flutter/material.dart';
import 'package:movi/src/features/player/domain/value_objects/video_fit_mode.dart';
import 'package:movi/l10n/app_localizations.dart';

/// Menu de sélection du mode d'affichage vidéo
class VideoFitModeSelectionMenu extends StatelessWidget {
  const VideoFitModeSelectionMenu({
    super.key,
    required this.currentMode,
    required this.onModeSelected,
  });

  final VideoFitMode currentMode;
  final Future<void> Function(VideoFitMode mode) onModeSelected;

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
                    AppLocalizations.of(context)!.videoFitModeMenuTitle,
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
            // Liste des modes
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Option "Proportions de base" (contain)
                  ListTile(
                    leading: Icon(
                      currentMode == VideoFitMode.contain
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: currentMode == VideoFitMode.contain
                          ? Colors.white
                          : Colors.white70,
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.videoFitModeContain,
                      style: TextStyle(
                        color: currentMode == VideoFitMode.contain
                            ? Colors.white
                            : Colors.white70,
                        fontWeight: currentMode == VideoFitMode.contain
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    selected: currentMode == VideoFitMode.contain,
                    selectedTileColor: const Color(0xFF2A2A2A),
                    onTap: () async {
                      await onModeSelected(VideoFitMode.contain);
                      if (!context.mounted) return;
                      Navigator.of(context).pop(VideoFitMode.contain);
                    },
                  ),
                  // Option "Tout l'espace" (cover)
                  ListTile(
                    leading: Icon(
                      currentMode == VideoFitMode.cover
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: currentMode == VideoFitMode.cover
                          ? Colors.white
                          : Colors.white70,
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.videoFitModeCover,
                      style: TextStyle(
                        color: currentMode == VideoFitMode.cover
                            ? Colors.white
                            : Colors.white70,
                        fontWeight: currentMode == VideoFitMode.cover
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    selected: currentMode == VideoFitMode.cover,
                    selectedTileColor: const Color(0xFF2A2A2A),
                    onTap: () async {
                      await onModeSelected(VideoFitMode.cover);
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
    );
  }
}

