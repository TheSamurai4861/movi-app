/// Utilitaire pour formater les codes de langue
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
}
