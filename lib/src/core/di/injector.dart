import 'package:get_it/get_it.dart';

import '../utils/logger.dart';
import 'services/content_repository.dart';
import 'services/preferences_service.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  sl.registerLazySingleton<AppLogger>(() => AppLogger());
  sl.registerLazySingleton<ContentRepository>(() => FakeContentRepository());
  sl.registerLazySingleton<PreferencesService>(() => FakePreferencesService());
}
