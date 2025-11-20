import 'package:media_kit/media_kit.dart';

class LanguageFormatter {
  /// Formate un code de langue en nom lisible
  /// Gère les codes courts (fr), les codes avec région (FR_fr, fr-FR), etc.
  static String formatLanguageCode(String? code) {
    if (code == null || code.isEmpty) return 'Inconnu';

    // Nettoyer le code (enlever les underscores, tirets, etc.)
    final cleanCode = code
        .replaceAll('_', '-')
        .replaceAll(' ', '-')
        .toLowerCase()
        .split('-')
        .first;

    // Mapping des codes de langue courants
    const languageMap = {
      'fr': 'Français',
      'en': 'Anglais',
      'es': 'Espagnol',
      'de': 'Allemand',
      'it': 'Italien',
      'pt': 'Portugais',
      'ru': 'Russe',
      'ja': 'Japonais',
      'ko': 'Coréen',
      'zh': 'Chinois',
      'ar': 'Arabe',
      'nl': 'Néerlandais',
      'pl': 'Polonais',
      'tr': 'Turc',
      'sv': 'Suédois',
      'da': 'Danois',
      'no': 'Norvégien',
      'fi': 'Finnois',
      'cs': 'Tchèque',
      'hu': 'Hongrois',
      'ro': 'Roumain',
      'el': 'Grec',
      'he': 'Hébreu',
      'th': 'Thaï',
      'vi': 'Vietnamien',
      'id': 'Indonésien',
      'hi': 'Hindi',
      'uk': 'Ukrainien',
    };

    return languageMap[cleanCode] ?? code.toUpperCase();
  }

  /// Formate un code de langue avec région si disponible
  /// Ex: "fr-FR" -> "Français (France)"
  static String formatLanguageCodeWithRegion(String? code) {
    if (code == null || code.isEmpty) return 'Inconnu';

    final parts = code
        .replaceAll('_', '-')
        .replaceAll(' ', '-')
        .toLowerCase()
        .split('-');

    if (parts.isEmpty) return 'Inconnu';

    final langCode = parts.first;
    final regionCode = parts.length > 1 ? parts[1].toUpperCase() : null;

    final language = formatLanguageCode(langCode);

    if (regionCode != null && regionCode != langCode.toUpperCase()) {
      return '$language ($regionCode)';
    }

    return language;
  }

  static String? detectLanguageCodeFromTitle(String title) {
    final t = title.toLowerCase();
    const patterns = {
      'fr': ['fr', 'french', 'français', 'francais'],
      'en': ['en', 'english', 'anglais'],
      'es': ['es', 'spanish', 'espagnol'],
      'de': ['de', 'german', 'allemand'],
      'it': ['it', 'italian', 'italien'],
      'pt': ['pt', 'portuguese', 'portugais'],
      'ru': ['ru', 'russian', 'russe'],
      'ja': ['ja', 'japanese', 'japonais'],
      'ko': ['ko', 'korean', 'coréen', 'coreen'],
      'zh': ['zh', 'chinese', 'chinois'],
      'ar': ['ar', 'arabic', 'arabe'],
      'nl': ['nl', 'dutch', 'néerlandais', 'neerlandais'],
      'pl': ['pl', 'polish', 'polonais'],
      'tr': ['tr', 'turkish', 'turc'],
      'sv': ['sv', 'swedish', 'suédois', 'suedois'],
      'da': ['da', 'danish', 'danois'],
      'no': ['no', 'norwegian', 'norvégien', 'norvegien'],
      'fi': ['fi', 'finnish', 'finnois'],
      'cs': ['cs', 'czech', 'tchèque', 'tcheque'],
      'hu': ['hu', 'hungarian', 'hongrois'],
      'ro': ['ro', 'romanian', 'roumain'],
      'el': ['el', 'greek', 'grec'],
      'he': ['he', 'hebrew', 'hébreu', 'hebreu'],
      'th': ['th', 'thai', 'thaï', 'thai'],
      'vi': ['vi', 'vietnamese', 'vietnamien'],
      'id': ['id', 'indonesian', 'indonésien', 'indonesien'],
      'hi': ['hi', 'hindi'],
      'uk': ['uk', 'ukrainian', 'ukrainien'],
    };

    for (final entry in patterns.entries) {
      for (final p in entry.value) {
        if (t.contains(p)) return entry.key;
      }
    }
    return null;
  }

  static String formatTrackLabel(SubtitleTrack track) {
    final code = _normalizeLanguage(track.language) ??
        (track.title != null ? detectLanguageCodeFromTitle(track.title!) : null);
    if (code != null) {
      return formatLanguageCodeWithRegion(code);
    }
    if (track.title != null && track.title!.isNotEmpty) {
      return track.title!;
    }
    return '';
  }

  static String formatTrackLabelAudio(AudioTrack track) {
    final code = _normalizeLanguage(track.language) ??
        (track.title != null ? detectLanguageCodeFromTitle(track.title!) : null);
    if (code != null) {
      return formatLanguageCodeWithRegion(code);
    }
    if (track.title != null && track.title!.isNotEmpty) {
      return track.title!;
    }
    return '';
  }

  static String? normalizeLanguageCode(String? code) {
    if (code == null || code.isEmpty) return null;
    final normalized = code.trim()
        .replaceAll('_', '-')
        .replaceAll(' ', '-')
        .toLowerCase()
        .split('-')
        .first;
    return normalized.isEmpty ? null : normalized;
  }

  static String? _normalizeLanguage(String? code) {
    if (code == null || code.isEmpty) return null;
    final normalized = code
        .replaceAll('_', '-')
        .replaceAll(' ', '-')
        .toLowerCase()
        .split('-')
        .first;
    return normalized.isEmpty ? null : normalized;
  }
}
