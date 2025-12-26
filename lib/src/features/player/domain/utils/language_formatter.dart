
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
      'fr': [
        'fr',
        'french',
        'français',
        'francais',
        'fre', // ISO 639-2/3
      ],
      'en': [
        'en',
        'english',
        'anglais',
        'eng', // ISO 639-2/3
      ],
      'es': ['es', 'spanish', 'espagnol', 'spa'], // ISO 639-2/3
      'de': ['de', 'german', 'allemand', 'deu', 'ger'], // ISO 639-2/3
      'it': ['it', 'italian', 'italien', 'ita'], // ISO 639-2/3
      'pt': ['pt', 'portuguese', 'portugais', 'por'], // ISO 639-2/3
      'ru': ['ru', 'russian', 'russe', 'rus'], // ISO 639-2/3
      'ja': ['ja', 'japanese', 'japonais', 'jpn'], // ISO 639-2/3
      'ko': ['ko', 'korean', 'coréen', 'coreen', 'kor'], // ISO 639-2/3
      'zh': ['zh', 'chinese', 'chinois', 'zho', 'chi'], // ISO 639-2/3
      'ar': ['ar', 'arabic', 'arabe', 'ara'], // ISO 639-2/3
      'nl': [
        'nl',
        'dutch',
        'néerlandais',
        'neerlandais',
        'nld',
        'dut',
      ], // ISO 639-2/3
      'pl': ['pl', 'polish', 'polonais', 'pol'], // ISO 639-2/3
      'tr': ['tr', 'turkish', 'turc', 'tur'], // ISO 639-2/3
      'sv': ['sv', 'swedish', 'suédois', 'suedois', 'swe'], // ISO 639-2/3
      'da': ['da', 'danish', 'danois', 'dan'], // ISO 639-2/3
      'no': [
        'no',
        'norwegian',
        'norvégien',
        'norvegien',
        'nor',
        'nob',
      ], // ISO 639-2/3
      'fi': ['fi', 'finnish', 'finnois', 'fin'], // ISO 639-2/3
      'cs': ['cs', 'czech', 'tchèque', 'tcheque', 'ces', 'cze'], // ISO 639-2/3
      'hu': ['hu', 'hungarian', 'hongrois', 'hun'], // ISO 639-2/3
      'ro': ['ro', 'romanian', 'roumain', 'ron', 'rum'], // ISO 639-2/3
      'el': ['el', 'greek', 'grec', 'ell', 'gre'], // ISO 639-2/3
      'he': ['he', 'hebrew', 'hébreu', 'hebreu', 'heb'], // ISO 639-2/3
      'th': ['th', 'thai', 'thaï', 'thai'], // ISO 639-2/3
      'vi': ['vi', 'vietnamese', 'vietnamien', 'vie'], // ISO 639-2/3
      'id': [
        'id',
        'indonesian',
        'indonésien',
        'indonesien',
        'ind',
      ], // ISO 639-2/3
      'hi': ['hi', 'hindi', 'hin'], // ISO 639-2/3
      'uk': ['uk', 'ukrainian', 'ukrainien', 'ukr'], // ISO 639-2/3
    };

    // Vérifier d'abord les correspondances exactes (pour "French", "English", etc.)
    for (final entry in patterns.entries) {
      for (final p in entry.value) {
        // Correspondance exacte ou comme mot complet
        if (t == p ||
            t.startsWith('$p ') ||
            t.endsWith(' $p') ||
            t.contains(' $p ')) {
          return entry.key;
        }
      }
    }

    // Ensuite vérifier les correspondances partielles (pour "French Forced", etc.)
    for (final entry in patterns.entries) {
      for (final p in entry.value) {
        if (t.contains(p)) return entry.key;
      }
    }
    return null;
  }


  static String? normalizeLanguageCode(String? code) {
    if (code == null || code.isEmpty) return null;
    final normalized = code
        .trim()
        .replaceAll('_', '-')
        .replaceAll(' ', '-')
        .toLowerCase()
        .split('-')
        .first;
    if (normalized.isEmpty) return null;

    // Mapping des codes ISO 639-2/3 lettres vers codes ISO 639-1
    const iso639Mapping = {
      'fre': 'fr', // Français (ISO 639-2)
      'fra': 'fr', // Français (ISO 639-3)
      'eng': 'en', // Anglais (ISO 639-2/3)
      'spa': 'es', // Espagnol (ISO 639-2/3)
      'deu': 'de', // Allemand (ISO 639-3)
      'ger': 'de', // Allemand (ISO 639-2)
      'ita': 'it', // Italien (ISO 639-2/3)
      'por': 'pt', // Portugais (ISO 639-2/3)
      'rus': 'ru', // Russe (ISO 639-2/3)
      'jpn': 'ja', // Japonais (ISO 639-2/3)
      'kor': 'ko', // Coréen (ISO 639-2/3)
      'zho': 'zh', // Chinois (ISO 639-3)
      'chi': 'zh', // Chinois (ISO 639-2)
      'ara': 'ar', // Arabe (ISO 639-2/3)
      'nld': 'nl', // Néerlandais (ISO 639-3)
      'dut': 'nl', // Néerlandais (ISO 639-2)
      'pol': 'pl', // Polonais (ISO 639-2/3)
      'tur': 'tr', // Turc (ISO 639-2/3)
      'swe': 'sv', // Suédois (ISO 639-2/3)
      'dan': 'da', // Danois (ISO 639-2/3)
      'nor': 'no', // Norvégien (ISO 639-3)
      'nob': 'no', // Norvégien Bokmål (ISO 639-2)
      'fin': 'fi', // Finnois (ISO 639-2/3)
      'ces': 'cs', // Tchèque (ISO 639-3)
      'cze': 'cs', // Tchèque (ISO 639-2)
      'hun': 'hu', // Hongrois (ISO 639-2/3)
      'ron': 'ro', // Roumain (ISO 639-3)
      'rum': 'ro', // Roumain (ISO 639-2)
      'ell': 'el', // Grec (ISO 639-3)
      'gre': 'el', // Grec (ISO 639-2)
      'heb': 'he', // Hébreu (ISO 639-2/3)
      'vie': 'vi', // Vietnamien (ISO 639-2/3)
      'ind': 'id', // Indonésien (ISO 639-2/3)
      'hin': 'hi', // Hindi (ISO 639-2/3)
      'ukr': 'uk', // Ukrainien (ISO 639-2/3)
    };

    // Si c'est un code ISO 639-2/3, le convertir en ISO 639-1
    if (normalized.length == 3 && iso639Mapping.containsKey(normalized)) {
      return iso639Mapping[normalized];
    }

    return normalized;
  }
}
