import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:movi/src/features/player/domain/utils/language_formatter.dart';

/// Menu de sélection des pistes de sous-titres
class SubtitleTrackSelectionMenu extends StatelessWidget {
  const SubtitleTrackSelectionMenu({
    super.key,
    required this.tracks,
    required this.currentTrack,
    required this.onTrackSelected,
    required this.onDisable,
  });

  final List<SubtitleTrack> tracks;
  final SubtitleTrack? currentTrack;
  final Future<void> Function(SubtitleTrack track) onTrackSelected;
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
                  const Text(
                    'Sous-titres',
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
                    return ListTile(
                      leading: const Icon(Icons.radio_button_unchecked,
                          color: Colors.white70),
                      title: const Text(
                        'Désactiver',
                        style: TextStyle(color: Colors.white),
                      ),
                      selected: currentTrack == null,
                      selectedTileColor: const Color(0xFF2A2A2A),
                      onTap: () async {
                        await onDisable();
                        Navigator.of(context).pop(null);
                      },
                    );
                  }
                  
                  final track = tracks[index - 1];
                  final isSelected = currentTrack?.id == track.id;
                  
                  // Formater le titre de la piste
                  final trackTitle = _formatTrackTitle(track);
                  
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
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          )
                        : null,
                    selected: isSelected,
                    selectedTileColor: const Color(0xFF2A2A2A),
                    onTap: () async {
                      await onTrackSelected(track);
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

  String _formatTrackTitle(SubtitleTrack track) {
    // Essayer d'extraire la langue depuis le code de langue ou le titre
    String? languageCode;
    
    if (track.language != null && track.language!.isNotEmpty) {
      languageCode = track.language;
    } else if (track.title != null && track.title!.isNotEmpty) {
      // Essayer d'extraire un code de langue depuis le titre
      final title = track.title!.toLowerCase();
      // Chercher des patterns comme "fr", "french", "français", etc.
      if (title.contains('fr') || title.contains('french') || title.contains('français')) {
        languageCode = 'fr';
      } else if (title.contains('en') || title.contains('english') || title.contains('anglais')) {
        languageCode = 'en';
      } else if (title.contains('es') || title.contains('spanish') || title.contains('espagnol')) {
        languageCode = 'es';
      } else if (title.contains('de') || title.contains('german') || title.contains('allemand')) {
        languageCode = 'de';
      } else if (title.contains('it') || title.contains('italian') || title.contains('italien')) {
        languageCode = 'it';
      }
    }
    
    if (languageCode != null) {
      return LanguageFormatter.formatLanguageCodeWithRegion(languageCode);
    }
    
    // Fallback : utiliser le titre ou un label par défaut
    if (track.title != null && track.title!.isNotEmpty) {
      return track.title!;
    }
    
    return 'Piste ${track.id}';
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

  final List<AudioTrack> tracks;
  final AudioTrack? currentTrack;
  final Future<void> Function(AudioTrack track) onTrackSelected;

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
                  const Text(
                    'Audio',
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
                  final trackTitle = _formatTrackTitle(track);
                  
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
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          )
                        : null,
                    selected: isSelected,
                    selectedTileColor: const Color(0xFF2A2A2A),
                    onTap: () async {
                      await onTrackSelected(track);
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

  String _formatTrackTitle(AudioTrack track) {
    // Essayer d'extraire la langue depuis le code de langue ou le titre
    String? languageCode;
    
    if (track.language != null && track.language!.isNotEmpty) {
      languageCode = track.language;
    } else if (track.title != null && track.title!.isNotEmpty) {
      // Essayer d'extraire un code de langue depuis le titre
      final title = track.title!.toLowerCase();
      // Chercher des patterns comme "fr", "french", "français", etc.
      if (title.contains('fr') || title.contains('french') || title.contains('français')) {
        languageCode = 'fr';
      } else if (title.contains('en') || title.contains('english') || title.contains('anglais')) {
        languageCode = 'en';
      } else if (title.contains('es') || title.contains('spanish') || title.contains('espagnol')) {
        languageCode = 'es';
      } else if (title.contains('de') || title.contains('german') || title.contains('allemand')) {
        languageCode = 'de';
      } else if (title.contains('it') || title.contains('italian') || title.contains('italien')) {
        languageCode = 'it';
      }
    }
    
    if (languageCode != null) {
      return LanguageFormatter.formatLanguageCodeWithRegion(languageCode);
    }
    
    // Fallback : utiliser le titre ou un label par défaut
    if (track.title != null && track.title!.isNotEmpty) {
      return track.title!;
    }
    
    return 'Piste ${track.id}';
  }
}

