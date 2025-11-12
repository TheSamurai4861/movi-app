// lib/src/features/category_browser/data/category_browser_data_module.dart
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/category_browser/domain/repositories/category_repository.dart';
import 'package:movi/src/features/category_browser/data/datasources/category_local_data_source.dart';
import 'package:movi/src/features/category_browser/data/repositories/category_repository_impl.dart';

class CategoryBrowserDataModule {
  static void register() {
    if (sl.isRegistered<CategoryRepository>()) return;

    sl.registerLazySingleton<CategoryLocalDataSource>(
      () => CategoryLocalDataSource(sl<IptvLocalRepository>()),
    );

    sl.registerLazySingleton<CategoryRepository>(
      () => CategoryRepositoryImpl(sl<CategoryLocalDataSource>()),
    );
  }
}
