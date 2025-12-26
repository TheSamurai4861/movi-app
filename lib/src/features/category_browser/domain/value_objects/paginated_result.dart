// Modèle générique de résultat paginé pour la navigation par catégories.
class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.page,
    required this.hasMore,
    this.totalCount,
  });

  /// Éléments de la page courante.
  final List<T> items;

  /// Numéro de page (à partir de 1).
  final int page;

  /// Indique s'il reste d'autres pages à charger.
  final bool hasMore;

  /// Nombre total d'éléments (optionnel).
  final int? totalCount;
}
