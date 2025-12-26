import 'package:media_kit/media_kit.dart';
import 'package:movi/src/core/preferences/player_preferences.dart';
import 'package:movi/src/features/player/domain/utils/language_formatter.dart';

class PreferredTracksSelection {
  PreferredTracksSelection({
    this.audio,
    this.subtitle,
    this.subtitlesEnabled = false,
  });

  final AudioTrack? audio;
  final SubtitleTrack? subtitle;
  final bool subtitlesEnabled;
}

class PreferredTracksSelector {
  PreferredTracksSelector({required PlayerPreferences prefs}) : _prefs = prefs;

  final PlayerPreferences _prefs;

  PreferredTracksSelection select(Tracks tracks) {
    AudioTrack? selectedAudio;
    SubtitleTrack? selectedSubtitle;
    var enableSubtitles = false;

    // Audio selection
    if (tracks.audio.isNotEmpty) {
      final preferredAudio = _prefs.preferredAudioLanguage;
      if (preferredAudio != null && preferredAudio.isNotEmpty) {
        for (final track in tracks.audio) {
          final code = _extractLanguageCodeFromTrack(track);
          if (_matchesLanguageCode(code, preferredAudio)) {
            selectedAudio = track;
            break;
          }
        }
      }
    }

    // Subtitle selection
    if (tracks.subtitle.isNotEmpty) {
      final preferredSubtitle = _prefs.preferredSubtitleLanguage;
      if (preferredSubtitle != null && preferredSubtitle.isNotEmpty) {
        for (final track in tracks.subtitle) {
          final code = _extractLanguageCodeFromTrack(track);
          if (_matchesLanguageCode(code, preferredSubtitle)) {
            selectedSubtitle = track;
            enableSubtitles = true;
            break;
          }
        }
      }
    }

    return PreferredTracksSelection(
      audio: selectedAudio,
      subtitle: selectedSubtitle,
      subtitlesEnabled: enableSubtitles,
    );
  }

  String? _normalizeLanguageCode(String? code) =>
      LanguageFormatter.normalizeLanguageCode(code);

  bool _matchesLanguageCode(String? trackLanguage, String? preferredCode) {
    if (trackLanguage == null || preferredCode == null) return false;
    final normalizedTrack = _normalizeLanguageCode(trackLanguage);
    final normalizedPreferred = _normalizeLanguageCode(preferredCode);
    return normalizedTrack != null &&
        normalizedPreferred != null &&
        normalizedTrack == normalizedPreferred;
  }

  String? _extractLanguageCodeFromTrack(dynamic track) {
    if (track.language != null && track.language!.isNotEmpty) {
      return LanguageFormatter.normalizeLanguageCode(track.language);
    }
    if (track.title != null && track.title!.isNotEmpty) {
      return LanguageFormatter.detectLanguageCodeFromTitle(track.title!);
    }
    return null;
  }
}