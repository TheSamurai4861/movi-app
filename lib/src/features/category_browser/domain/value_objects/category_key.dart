// lib/src/features/category_browser/domain/value_objects/category_key.dart
import 'package:equatable/equatable.dart';

/// Clé de catégorie visible au format `<alias>/<categoryTitle>`.
/// - `alias` identifie la source (ex: `premium-ott.com`)
/// - `title` est le titre humain de la catégorie (ex: `Action`)
class CategoryKey extends Equatable {
  const CategoryKey({required this.alias, required this.title});

  final String alias;
  final String title;

  /// Parse une clé visible (ex: "premium-ott.com/Action").
  ///
  /// Règles:
  /// - Trim des espaces en entrée.
  /// - Si aucun `/` valide n'est trouvé, utilise `raw` pour `alias` et `title`.
  /// - Si plusieurs `/` sont présents, seule la première occurrence sépare
  ///   l'alias du titre (le reste appartient au titre).
  ///
  /// Lance [ArgumentError] si `raw` est vide après trim.
  factory CategoryKey.parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
        raw,
        'raw',
        'CategoryKey.parse: la clé ne peut pas être vide',
      );
    }

    final idx = trimmed.indexOf('/');
    if (idx >= 0 && idx < trimmed.length - 1) {
      final alias = trimmed.substring(0, idx).trim();
      final title = trimmed.substring(idx + 1).trim();
      return CategoryKey(
        alias: alias.isEmpty ? trimmed : alias,
        title: title.isEmpty ? trimmed : title,
      );
    }

    // Pas de séparateur explicite: considérer toute la chaîne comme alias+title.
    return CategoryKey(alias: trimmed, title: trimmed);
  }

  /// Représentation sérialisée (clé visible) sous la forme `<alias>/<title>`.
  String toVisibleString() => '$alias/$title';

  @override
  List<Object?> get props => [alias, title];
}
