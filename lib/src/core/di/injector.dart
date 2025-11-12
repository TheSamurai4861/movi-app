import 'package:get_it/get_it.dart';

import '../config/models/app_config.dart';
import '../config/services/secret_store.dart';
import '../network/config/network_module.dart';
import '../network/network_executor.dart';
import '../network/interceptors/locale_interceptor.dart';
import '../iptv/config/iptv_module.dart';
import '../preferences/locale_preferences.dart';
import '../state/app_state_controller.dart';
import '../../shared/data/services/tmdb_client.dart';
import '../../shared/data/services/tmdb_image_resolver.dart';
import '../../features/movie/data/movie_data_module.dart';
import '../../features/tv/data/tv_data_module.dart';
import '../../features/person/data/person_data_module.dart';
import '../../features/saga/data/saga_data_module.dart';
import '../../features/search/data/search_data_module.dart';
import '../../features/playlist/data/playlist_data_module.dart';
import '../../features/home/data/home_feed_data_module.dart';
import '../../features/library/data/library_data_module.dart';
import '../../features/category_browser/data/category_browser_data_module.dart';
import '../../features/settings/data/settings_data_module.dart';
import '../storage/services/storage_module.dart';
import '../utils/logger.dart';

final sl = GetIt.instance;

Future<void> initDependencies({
  AppConfig? appConfig,
  SecretStore? secretStore,
  LocaleCodeProvider? localeProvider,
}) async {
  _registerLogging();
  if (appConfig != null && !sl.isRegistered<AppConfig>()) {
    sl.registerSingleton<AppConfig>(appConfig);
  }
  if (secretStore != null && !sl.isRegistered<SecretStore>()) {
    sl.registerSingleton<SecretStore>(secretStore);
  }
  if (!sl.isRegistered<LocalePreferences>()) {
    sl.registerLazySingleton<LocalePreferences>(() => LocalePreferences());
  }
  await StorageModule.register();
  _registerNetwork(localeProvider: localeProvider);
  _registerTmdb();
  _registerState();
}

void _registerLogging() {
  if (!sl.isRegistered<AppLogger>()) {
    sl.registerLazySingleton<AppLogger>(() => AppLogger());
  }
}

void _registerNetwork({LocaleCodeProvider? localeProvider}) {
  if (!sl.isRegistered<SecretStore>()) {
    sl.registerLazySingleton<SecretStore>(() => SecretStore());
  }
  if (sl.isRegistered<AppConfig>()) {
    NetworkModule.register(localeProvider: localeProvider);
    IptvModule.register();
  }
}

void _registerTmdb() {
  if (!sl.isRegistered<TmdbImageResolver>()) {
    sl.registerLazySingleton<TmdbImageResolver>(
      () => const TmdbImageResolver(),
    );
  }

  // Si déjà enregistré, ne rien faire.
  if (sl.isRegistered<TmdbClient>()) return;

  // On ne peut pas créer TmdbClient si les dépendances ne sont pas prêtes.
  if (!sl.isRegistered<NetworkExecutor>() || !sl.isRegistered<AppConfig>()) {
    return;
  }

  // TmdbClient attend des paramètres NOMMÉS :
  // TmdbClient({ required NetworkExecutor executor, required NetworkEndpoints endpoints })
  sl.registerLazySingleton<TmdbClient>(
    () => TmdbClient(
      executor: sl<NetworkExecutor>(),
      endpoints: sl<AppConfig>().network,
    ),
  );

  MovieDataModule.register();
  TvDataModule.register();
  PersonDataModule.register();
  SagaDataModule.register();
  SearchDataModule.register();
  PlaylistDataModule.register();
  HomeFeedDataModule.register();
  LibraryDataModule.register();
  CategoryBrowserDataModule.register();
  SettingsDataModule.register();
}

void _registerState() {
  if (!sl.isRegistered<AppStateController>()) {
    sl.registerLazySingleton<AppStateController>(
      () => AppStateController(sl<LocalePreferences>()),
    );
  }
}
