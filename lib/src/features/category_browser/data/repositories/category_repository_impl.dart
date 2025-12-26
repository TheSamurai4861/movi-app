// lib/src/features/category_browser/data/repositories/category_repository_impl.dart
import 'package:movi/src/features/category_browser/data/datasources/category_local_data_source.dart';

import 'package:movi/src/features/category_browser/domain/repositories/category_repository.dart';
import 'package:movi/src/features/category_browser/domain/value_objects/category_key.dart';
import 'package:movi/src/features/category_browser/domain/value_objects/paginated_result.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._local);

  final CategoryLocalDataSource _local;

  @override
  Future<List<ContentReference>> getItems(CategoryKey key) async {
    return _local.listItems(key);
  }

  @override
  Future<PaginatedResult<ContentReference>> getItemsPage(
    CategoryKey key,
    int page,
    int pageSize,
  ) {
    return _local.listItemsPage(key, page: page, pageSize: pageSize);
  }
}
