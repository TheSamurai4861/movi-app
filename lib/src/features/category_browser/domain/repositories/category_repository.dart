// lib/src/features/category_browser/domain/repositories/category_repository.dart
import '../../../../shared/domain/value_objects/content_reference.dart';
import '../value_objects/category_key.dart';

/// Contrat du repository de navigation par catégorie IPTV.
abstract class CategoryRepository {
  /// Retourne la liste complète des items (ContentReference) pour une catégorie.
  /// La pagination est gérée côté présentation.
  Future<List<ContentReference>> getItems(CategoryKey key);
}