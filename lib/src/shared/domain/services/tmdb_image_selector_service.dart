/// Service utilitaire pour sélectionner les meilleures images TMDB
/// (posters, logos) à partir des structures JSON renvoyées par l'API.
///
/// Règles :
/// - Poster : priorité **no-lang** → **en** → meilleur score (`vote_average`).
/// - Logo   : priorité **langue app** (si fournie) → **en** → **no-lang** →
///   meilleur score, en privilégiant les logos "larges" (ratio >= 2.0).
class TmdbImageSelectorService {
  const TmdbImageSelectorService._();

  /// Sélectionne le meilleur `file_path` pour un poster.
  static String? selectPosterPath(List<dynamic> posters) {
    if (posters.isEmpty) return null;
    String? pathOf(Map<String, dynamic> m) => m['file_path']?.toString();
    num scoreOf(Map<String, dynamic> m) => (m['vote_average'] as num?) ?? 0;

    final List<Map<String, dynamic>> list = posters
        .whereType<Map<String, dynamic>>()
        .where((m) => m['file_path'] != null)
        .toList();
    if (list.isEmpty) return null;

    final List<Map<String, dynamic>> noLang =
        list.where((m) => m['iso_639_1'] == null).toList()
          ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (noLang.isNotEmpty) return pathOf(noLang.first);

    final List<Map<String, dynamic>> en =
        list
            .where((m) => (m['iso_639_1']?.toString().toLowerCase() == 'en'))
            .toList()
          ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (en.isNotEmpty) return pathOf(en.first);

    list.sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    return pathOf(list.first);
  }

  /// Sélectionne le meilleur `file_path` pour un logo.
  ///
  /// [preferredLang] : code ISO 639-1 (ex. `fr` depuis `fr-FR`).
  static String? selectLogoPath(
    List<dynamic> logos, {
    String? preferredLang,
  }) {
    if (logos.isEmpty) return null;
    String? pathOf(Map<String, dynamic> m) => m['file_path']?.toString();
    num scoreOf(Map<String, dynamic> m) => (m['vote_average'] as num?) ?? 0;

    double ratioOf(Map<String, dynamic> m) {
      final w = m['width'];
      final h = m['height'];
      final dw = (w is num)
          ? w.toDouble()
          : double.tryParse(w?.toString() ?? '') ?? 0;
      final dh = (h is num)
          ? h.toDouble()
          : double.tryParse(h?.toString() ?? '') ?? 0;
      if (dw <= 0 || dh <= 0) return 0;
      return dw / dh;
    }

    final List<Map<String, dynamic>> list = logos
        .whereType<Map<String, dynamic>>()
        .where((m) => m['file_path'] != null)
        .toList();
    if (list.isEmpty) return null;

    List<Map<String, dynamic>> sortByScore(List<Map<String, dynamic>> l) =>
        (l..sort((a, b) => scoreOf(b).compareTo(scoreOf(a))));

    List<Map<String, dynamic>> preferWide(List<Map<String, dynamic>> l) {
      final wide = l.where((m) => ratioOf(m) >= 2.0).toList();
      if (wide.isNotEmpty) return sortByScore(wide);
      return sortByScore(l);
    }

    final pref = (preferredLang ?? '').split('-').first.toLowerCase().trim();

    bool isPng(Map<String, dynamic> m) {
      final p = pathOf(m)?.toLowerCase() ?? '';
      return p.endsWith('.png');
    }

    String? pickLang(String? iso639) {
      final List<Map<String, dynamic>> filtered;
      if (iso639 == null) {
        filtered = list
            .where((m) {
              final s = m['iso_639_1']?.toString().trim();
              return s == null || s.isEmpty;
            })
            .toList();
      } else {
        final iso = iso639.toLowerCase();
        filtered = list
            .where((m) => m['iso_639_1']?.toString().toLowerCase() == iso)
            .toList();
      }
      // Règle stricte : on ne retourne que des PNG.
      final pngOnly = filtered.where(isPng).toList();
      if (pngOnly.isEmpty) return null;
      final picked = preferWide(pngOnly);
      return picked.isEmpty ? null : pathOf(picked.first);
    }

    if (pref.isNotEmpty) {
      final p = pickLang(pref);
      if (p != null) return p;
    }

    final enPick = pickLang('en');
    if (enPick != null) return enPick;

    final noLangPick = pickLang(null);
    if (noLangPick != null) return noLangPick;

    // Dernier recours : n'importe quel PNG ; sinon aucun logo.
    final anyPng = list.where(isPng).toList();
    if (anyPng.isEmpty) return null;
    return pathOf(sortByScore(anyPng).first);
  }
}
