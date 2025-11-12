// lib/src/features/category_browser/data/category_browser_data_module.dart
import '../../../core/di/injector.dart';
import '../../../core/storage/repositories/iptv_local_repository.dart';
import '../domain/repositories/category_repository.dart';
import 'datasources/category_local_data_source.dart';
import 'repositories/category_repository_impl.dart';

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