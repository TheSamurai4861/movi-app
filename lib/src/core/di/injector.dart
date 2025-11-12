import 'package:get_it/get_it.dart';

import 'package:movi/src/core/config/config.dart';
import 'package:movi/src/core/network/config/network_module.dart';
import 'package:movi/src/core/network/network.dart';
import 'package:movi/src/features/iptv/data/iptv_data_module.dart';
import 'package:movi/src/core/preferences/preferences.dart';
import 'package:movi/src/core/state/state.dart';
import 'package:movi/src/shared/services.dart';
import 'package:movi/src/features/movie/data/movie_data_module.dart';
import 'package:movi/src/features/tv/data/tv_data_module.dart';
import 'package:movi/src/features/person/data/person_data_module.dart';
import 'package:movi/src/features/saga/data/saga_data_module.dart';
import 'package:movi/src/features/search/data/search_data_module.dart';
import 'package:movi/src/features/playlist/data/playlist_data_module.dart';
import 'package:movi/src/features/home/data/home_feed_data_module.dart';
import 'package:movi/src/features/library/data/library_data_module.dart';
import 'package:movi/src/features/category_browser/data/category_browser_data_module.dart';
import 'package:movi/src/features/settings/data/settings_data_module.dart';
import 'package:movi/src/core/storage/services/storage_module.dart';
import 'package:movi/src/core/logging/logging_module.dart';

final sl = GetIt.instance;

void _replace<T extends Object>(T instance) {
  if (sl.isRegistered<T>()) {
    sl.unregister<T>();
  }
  sl.registerSingleton<T>(instance);
}

void replace<T extends Object>(T instance) => _replace<T>(instance);

Future<void> initDependencies({
  AppConfig? appConfig,
  SecretStore? secretStore,
  LocaleCodeProvider? localeProvider,
}) async {
  _registerLogging();
  if (appConfig != null) {
    _replace<AppConfig>(appConfig);
  }
  if (secretStore != null) {
    _replace<SecretStore>(secretStore);
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
  LoggingModule.register();
}

void _registerNetwork({LocaleCodeProvider? localeProvider}) {
  if (!sl.isRegistered<SecretStore>()) {
    sl.registerLazySingleton<SecretStore>(() => SecretStore());
  }
  if (sl.isRegistered<AppConfig>()) {
    NetworkModule.register(localeProvider: localeProvider);
    IptvDataModule.register();
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
