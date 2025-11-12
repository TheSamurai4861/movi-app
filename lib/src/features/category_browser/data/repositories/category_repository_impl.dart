// lib/src/features/category_browser/data/repositories/category_repository_impl.dart
import 'package:movi/src/features/category_browser/data/datasources/category_local_data_source.dart';

import '../../../category_browser/domain/repositories/category_repository.dart';
import '../../../category_browser/domain/value_objects/category_key.dart';
import '../../../../shared/domain/value_objects/content_reference.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._local);

  final CategoryLocalDataSource _local;

  @override
  Future<List<ContentReference>> getItems(CategoryKey key) async {
    return _local.listItems(key);
  }
}
