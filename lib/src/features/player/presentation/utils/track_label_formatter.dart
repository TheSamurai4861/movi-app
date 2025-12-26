import 'package:movi/src/features/player/domain/value_objects/track_info.dart';

class TrackLabelFormatter {
  static String formatTrackLabel(TrackInfo track) {
    final code = getLanguageCode(track);
    if (code != null) {
      return _formatLanguageCodeWithRegion(code);
    }
    if (track.title != null && track.title!.isNotEmpty) {
      return track.title!;
    }
    return '';
  }

  static String? getLanguageCode(TrackInfo track) {
    return normalizeLanguageCode(track.language) ??
        (track.title != null
            ? _detectLanguageCodeFromTitle(track.title!)
            : null);
  }

  static String? normalizeLanguageCode(String? code) {
    if (code == null) return null;
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null;
    final normalized = trimmed
        .replaceAll('_', '-')
        .replaceAll(' ', '-')
        .toLowerCase()
        .split('-')
        .first;
    if (normalized.isEmpty) return null;
    const iso639Mapping = {
      'fre': 'fr',
      'fra': 'fr',
      'eng': 'en',
      'spa': 'es',
      'deu': 'de',
      'ger': 'de',
      'ita': 'it',
      'por': 'pt',
      'rus': 'ru',
      'jpn': 'ja',
      'kor': 'ko',
      'zho': 'zh',
      'chi': 'zh',
      'ara': 'ar',
      'nld': 'nl',
      'dut': 'nl',
      'pol': 'pl',
      'tur': 'tr',
      'swe': 'sv',
      'dan': 'da',
      'nor': 'no',
      'nob': 'no',
      'fin': 'fi',
      'ces': 'cs',
      'cze': 'cs',
      'hun': 'hu',
      'ron': 'ro',
      'rum': 'ro',
      'ell': 'el',
      'gre': 'el',
      'heb': 'he',
      'vie': 'vi',
      'ind': 'id',
      'hin': 'hi',
      'ukr': 'uk',
    };
    if (normalized.length == 3 && iso639Mapping.containsKey(normalized)) {
      return iso639Mapping[normalized];
    }
    return normalized;
  }

  static String _formatLanguageCodeWithRegion(String code) {
    final parts = code
        .replaceAll('_', '-')
        .replaceAll(' ', '-')
        .toLowerCase()
        .split('-');
    final langCode = parts.first;
    final regionCode = parts.length > 1 ? parts[1].toUpperCase() : null;
    final language = _formatLanguageCode(langCode);
    if (regionCode != null && regionCode != langCode.toUpperCase()) {
      return '$language ($regionCode)';
    }
    return language;
  }

  static String _formatLanguageCode(String code) {
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
    return languageMap[code] ?? code.toUpperCase();
  }

  static String? _detectLanguageCodeFromTitle(String title) {
    final t = title.toLowerCase();
    const patterns = {
      'fr': ['fr', 'french', 'français', 'francais', 'fre'],
      'en': ['en', 'english', 'anglais', 'eng'],
      'es': ['es', 'spanish', 'espagnol', 'spa'],
      'de': ['de', 'german', 'allemand', 'deu', 'ger', 'deutsch'],
      'it': ['it', 'italian', 'italien', 'ita'],
      'pt': ['pt', 'portuguese', 'portugais', 'por'],
      'ru': ['ru', 'russian', 'russe', 'rus'],
      'ja': ['ja', 'japanese', 'japonais', 'jpn'],
      'ko': ['ko', 'korean', 'coréen', 'coreen', 'kor'],
      'zh': ['zh', 'chinese', 'chinois', 'zho', 'chi'],
      'ar': ['ar', 'arabic', 'arabe', 'ara'],
      'nl': ['nl', 'dutch', 'néerlandais', 'neerlandais', 'nld', 'dut'],
      'pl': ['pl', 'polish', 'polonais', 'pol'],
      'tr': ['tr', 'turkish', 'turc', 'tur'],
      'sv': ['sv', 'swedish', 'suédois', 'suedois', 'swe'],
      'da': ['da', 'danish', 'danois', 'dan'],
      'no': ['no', 'norwegian', 'norvégien', 'norvegien', 'nor', 'nob'],
      'fi': ['fi', 'finnish', 'finnois', 'fin'],
      'cs': ['cs', 'czech', 'tchèque', 'tcheque', 'ces', 'cze'],
      'hu': ['hu', 'hungarian', 'hongrois', 'hun'],
      'ro': ['ro', 'romanian', 'roumain', 'ron', 'rum'],
      'el': ['el', 'greek', 'grec', 'ell', 'gre'],
      'he': ['he', 'hebrew', 'hébreu', 'hebreu', 'heb'],
      'th': ['th', 'thai', 'thaï', 'thai'],
      'vi': ['vi', 'vietnamese', 'vietnamien', 'vie'],
      'id': ['id', 'indonesian', 'indonésien', 'indonesien', 'ind'],
      'hi': ['hi', 'hindi', 'hin'],
      'uk': ['uk', 'ukrainian', 'ukrainien', 'ukr'],
    };
    for (final entry in patterns.entries) {
      for (final p in entry.value) {
        if (t == p ||
            t.startsWith('$p ') ||
            t.endsWith(' $p') ||
            t.contains(' $p ')) {
          return entry.key;
        }
      }
    }

    return null;
  }
}
