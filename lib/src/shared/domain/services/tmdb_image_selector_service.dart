/// Service utilitaire pour sélectionner les meilleures images TMDB
/// (posters, logos) à partir des structures JSON renvoyées par l'API.
///
/// Règles :
/// - Poster : priorité **no-lang** → **en** → meilleur score (`vote_average`).
/// - Logo   : priorité **en** → **no-lang** → meilleur score, en privilégiant
///   les logos "larges" (ratio largeur/hauteur >= 2.0) quand c'est possible.
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
  static String? selectLogoPath(List<dynamic> logos) {
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

    final List<Map<String, dynamic>> en = list
        .where((m) => (m['iso_639_1']?.toString().toLowerCase() == 'en'))
        .toList();
    final enPref = preferWide(en);
    if (enPref.isNotEmpty) return pathOf(enPref.first);

    final List<Map<String, dynamic>> noLang = list
        .where((m) => m['iso_639_1'] == null)
        .toList();
    final noLangPref = preferWide(noLang);
    if (noLangPref.isNotEmpty) return pathOf(noLangPref.first);

    return pathOf(sortByScore(list).first);
  }
}
