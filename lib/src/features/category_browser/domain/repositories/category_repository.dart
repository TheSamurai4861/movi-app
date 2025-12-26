// lib/src/features/category_browser/domain/repositories/category_repository.dart
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/category_browser/domain/value_objects/category_key.dart';
import 'package:movi/src/features/category_browser/domain/value_objects/paginated_result.dart';

/// Contrat du repository de navigation par catégorie IPTV.
abstract class CategoryRepository {
  /// Retourne la liste complète des items (ContentReference) pour une catégorie.
  /// Utilisé pour compatibilité ou cas particuliers sans pagination.
  Future<List<ContentReference>> getItems(CategoryKey key);

  /// Retourne une page d'items pour une catégorie donnée.
  ///
  /// La pagination est gérée côté Data/Domain, pas dans la présentation.
  Future<PaginatedResult<ContentReference>> getItemsPage(
    CategoryKey key,
    int page,
    int pageSize,
  );
}
