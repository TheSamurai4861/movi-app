// lib/src/features/category_browser/data/datasources/category_local_data_source.dart

import 'package:movi/src/features/iptv/application/iptv_catalog_reader.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/category_browser/domain/value_objects/category_key.dart';

class CategoryLocalDataSource {
  CategoryLocalDataSource(this._catalogReader);

  final IptvCatalogReader _catalogReader;

  /// Récupère toutes les références de contenu pour une catégorie donnée.
  Future<List<ContentReference>> listItems(CategoryKey key) async {
    return _catalogReader.listCategory(key);
  }
}
