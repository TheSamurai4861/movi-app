import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/playlist/application/services/playlist_filter_service.dart';

class PlaylistApplicationModule {
  static void register() {
    if (!sl.isRegistered<PlaylistFilterService>()) {
      sl.registerLazySingleton<PlaylistFilterService>(
        () => PlaylistFilterService(sl<IptvLocalRepository>()),
      );
    }
  }
}