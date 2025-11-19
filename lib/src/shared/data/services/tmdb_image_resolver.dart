// ignore_for_file: public_member_api_docs, deprecated_member_use

/// TMDB Image URL resolver.
/// Responsabilité unique : convertir un `file_path` TMDB (ex: `/abc.jpg`)
/// en `Uri` consommable par l’application, avec gestion des tailles.
///
/// Règles :
/// - Si `path` est `null`, vide ou égal à la chaîne `"null"`, retourne `null`.
/// - Si `path` est déjà une URL absolue (http/https), elle est retournée telle quelle.
/// - Sinon on préfixe avec `baseUrl` et une taille valide (ex: `w500`, `w780`, `original`).
///
/// Bonnes pratiques :
/// - Utiliser des tailles cohérentes par type d’image (défauts fournis).
/// - Éviter `original` sur mobile/desktop si la performance mémoire est critique.
class TmdbImageResolver {
  const TmdbImageResolver({this.baseUrl = 'https://image.tmdb.org/t/p/'});

  /// Base URL du CDN TMDB (se termine toujours par `/t/p/`).
  final String baseUrl;

  /// Construit l’URL d’un poster (portrait).
  /// Taille par défaut : `w342`.
  Uri? poster(String? path, {String size = 'w342'}) =>
      _build(path, _sanitizeSize(size, fallback: 'w342'));

  /// Construit l’URL d’un backdrop (paysage).
  /// Taille par défaut : `w780`.
  Uri? backdrop(String? path, {String size = 'w780'}) =>
      _build(path, _sanitizeSize(size, fallback: 'w780'));

  Uri? heroPoster(
    String? posterPath,
    String? backdropPath, {
    String posterSize = 'w342',
    String backdropSize = 'w780',
  }) {
    return poster(posterPath, size: posterSize) ??
        backdrop(backdropPath, size: backdropSize);
  }

  TmdbImagePair resolvePair(
    String? posterPath,
    String? backdropPath, {
    String posterSize = 'w342',
    String backdropSize = 'w780',
  }) {
    final Uri? p = poster(posterPath, size: posterSize);
    final Uri? b = backdrop(backdropPath, size: backdropSize);
    return TmdbImagePair(poster: p, backdrop: b, preferred: p ?? b);
  }

  /// Construit l’URL d’un logo (transparent, centré).
  /// Taille par défaut : `w300`.
  Uri? logo(String? path, {String size = 'w300'}) =>
      _build(path, _sanitizeSize(size, fallback: 'w300'));

  /// Construit l’URL d’une image de scène (still).
  /// Taille par défaut : `w185`.
  Uri? still(String? path, {String size = 'w185'}) =>
      _build(path, _sanitizeSize(size, fallback: 'w185'));

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Normalise la taille. Autorise :
  ///  - `original`
  ///  - `w###` ou `h###` (2–4 chiffres)
  /// En cas de valeur invalide, applique `fallback`.
  String _sanitizeSize(String raw, {required String fallback}) {
    final s = (raw).trim();
    if (s == 'original') return s;
    final re = RegExp(r'^[wh]\d{2,4}$');
    return re.hasMatch(s) ? s : fallback;
  }

  /// Construit l’URI final en gérant :
  /// - chemins relatifs TMDB (avec ou sans `/` initial),
  /// - URLs absolues déjà complètes,
  /// - valeurs vides / "null".
  Uri? _build(String? path, String size) {
    if (path == null) return null;
    final p = path.trim();
    if (p.isEmpty || p == 'null') return null;

    // Si déjà absolu, on ne recompose pas.
    if (_looksAbsoluteUrl(p)) {
      return Uri.tryParse(p);
    }

    // TMDB retourne en général des chemins commençant par '/', on garantit cette propriété.
    final normalizedPath = p.startsWith('/') ? p : '/$p';

    // Concaténation sûre : baseUrl + size + normalizedPath
    final base = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return Uri.parse('$base$size$normalizedPath');
  }

  bool _looksAbsoluteUrl(String s) =>
      s.startsWith('http://') || s.startsWith('https://');

  // ---------------------------------------------------------------------------
  // Tailles standard suggérées (optionnel : utilitaires exploités côté appelant)
  // ---------------------------------------------------------------------------

  /// Tailles usuelles pour poster (documentation TMDB indicative).
  static const List<String> posterSizes = <String>[
    'w92',
    'w154',
    'w185',
    'w342',
    'w500',
    'w780',
    'original',
  ];

  /// Tailles usuelles pour backdrop.
  static const List<String> backdropSizes = <String>[
    'w300',
    'w780',
    'w1280',
    'original',
  ];

  /// Tailles usuelles pour logo.
  static const List<String> logoSizes = <String>[
    'w45',
    'w92',
    'w154',
    'w185',
    'w300',
    'w500',
    'original',
  ];

  /// Tailles usuelles pour still.
  static const List<String> stillSizes = <String>[
    'w92',
    'w185',
    'w300',
    'original',
  ];
}

class TmdbImagePair {
  const TmdbImagePair({
    required this.poster,
    required this.backdrop,
    required this.preferred,
  });
  final Uri? poster;
  final Uri? backdrop;
  final Uri? preferred;
}
