# Snapshot de dossier

**Dossier analysé :** `C:\Users\berny\DEV\Flutter\movi\lib\src\core\di`

## Arborescence

```text
di/
├── providers/
│   └── repository_providers.dart
├── di.dart
├── injector.dart
└── test_injector.dart
```

## Snapshots des fichiers

## di.dart

- Chemin absolu : `C:\Users\berny\DEV\Flutter\movi\lib\src\core\di\di.dart`
- Taille : `577` octets

```text
// Public entry-point for the dependency injection layer.
//
// This barrel exposes the global GetIt injector and the Riverpod bridge used
// by the UI and tests to access the registered services.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'package:movi/src/core/di/injector.dart';

// Service locator entry-points shared by the app.
export 'package:movi/src/core/di/injector.dart';

/// Expose GetIt via Riverpod so tests can override dependencies easily.
final slProvider = Provider<GetIt>((_) => sl);
```

## injector.dart

- Chemin absolu : `C:\Users\berny\DEV\Flutter\movi\lib\src\core\di\injector.dart`
- Taille : `25159` octets

```text
// FILE #48
// lib/src/core/di/di.dart

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/core/auth/auth_module.dart';
import 'package:movi/src/core/auth/domain/repositories/auth_repository.dart';
import 'package:movi/src/core/config/config.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/logging/logging_module.dart';
import 'package:movi/src/core/network/config/network_module.dart';
import 'package:movi/src/core/network/network.dart';
import 'package:movi/src/core/preferences/preferences.dart';
import 'package:movi/src/core/parental/application/services/parental_session_service.dart';
import 'package:movi/src/core/parental/data/datasources/pin_recovery_remote_data_source.dart';
import 'package:movi/src/core/parental/data/datasources/tmdb_content_rating_remote_data_source.dart';
import 'package:movi/src/core/parental/data/repositories/cached_content_rating_repository.dart';
import 'package:movi/src/core/parental/data/repositories/pin_recovery_repository_impl.dart';
import 'package:movi/src/core/parental/data/services/profile_pin_edge_service.dart';
import 'package:movi/src/core/parental/domain/repositories/content_rating_repository.dart';
import 'package:movi/src/core/parental/domain/repositories/pin_recovery_repository.dart';
import 'package:movi/src/core/parental/domain/services/age_policy.dart';
import 'package:movi/src/core/parental/domain/services/playlist_maturity_classifier.dart';
import 'package:movi/src/core/performance/performance_module.dart';
import 'package:movi/src/core/profile/data/datasources/supabase_profile_datasource.dart';
import 'package:movi/src/core/profile/data/repositories/fallback_profile_repository.dart';
import 'package:movi/src/core/profile/data/repositories/local_profile_repository.dart';
import 'package:movi/src/core/profile/data/repositories/supabase_profile_repository.dart';
import 'package:movi/src/core/profile/domain/repositories/profile_repository.dart';
import 'package:movi/src/core/reporting/application/usecases/report_content_problem.dart';
import 'package:movi/src/core/reporting/data/repositories/supabase_content_reports_repository.dart';
import 'package:movi/src/core/reporting/domain/repositories/content_reports_repository.dart';
import 'package:movi/src/core/state/state.dart';
import 'package:movi/src/core/storage/services/storage_module.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/core/supabase/supabase_module.dart';
import 'package:movi/src/core/startup/app_launch_orchestrator.dart';

import 'package:movi/src/features/category_browser/data/category_browser_data_module.dart';
import 'package:movi/src/features/home/data/home_feed_data_module.dart';
import 'package:movi/src/features/iptv/data/iptv_data_module.dart';
import 'package:movi/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart';
import 'package:movi/src/features/iptv/data/services/iptv_credentials_edge_service.dart';
import 'package:movi/src/features/library/data/library_data_module.dart';
import 'package:movi/src/features/library/application/services/cloud_sync_preferences.dart';
import 'package:movi/src/features/movie/data/movie_data_module.dart';
import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
import 'package:movi/src/features/person/data/person_data_module.dart';
import 'package:movi/src/features/playlist/data/playlist_data_module.dart';
import 'package:movi/src/features/saga/data/saga_data_module.dart';
import 'package:movi/src/features/search/data/search_data_module.dart';
import 'package:movi/src/features/settings/data/settings_data_module.dart';
import 'package:movi/src/features/tv/data/tv_data_module.dart';
import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';

impor

[... snapshot tronqué ...]
```

## test_injector.dart

- Chemin absolu : `C:\Users\berny\DEV\Flutter\movi\lib\src\core\di\test_injector.dart`
- Taille : `1147` octets

```text
import 'package:get_it/get_it.dart';

import 'package:movi/src/core/config/config.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/network/network.dart';

/// Disposable scope returned when initializing dependencies for tests.
class TestInjectorScope {
  TestInjectorScope._(this._popScope);

  final void Function() _popScope;

  void dispose() {
    _popScope();
  }
}

/// Helper used in tests to create an isolated GetIt scope with fake config.
Future<TestInjectorScope> initTestDependencies({
  AppConfig? appConfig,
  SecretStore? secretStore,
  LocaleCodeProvider? localeProvider,
  bool registerFeatureModules = false,
}) async {
  GetIt.I.pushNewScope();

  if (appConfig != null) {
    GetIt.I.registerSingleton<AppConfig>(appConfig);
  }
  if (secretStore != null) {
    GetIt.I.registerSingleton<SecretStore>(secretStore);
  }

  await initDependencies(
    appConfig: appConfig,
    secretStore: secretStore,
    localeProvider: localeProvider,
    registerFeatureModules: registerFeatureModules,
  );

  return TestInjectorScope._(() => GetIt.I.popScope());
}
```

## providers/repository_providers.dart

- Chemin absolu : `C:\Users\berny\DEV\Flutter\movi\lib\src\core\di\providers\repository_providers.dart`
- Taille : `517` octets

```text
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/features/category_browser/domain/repositories/category_repository.dart';

/// Providers d'infrastructure pour exposer les repositories aux features
/// sans coupler directement la présentation au service locator global.

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final locator = ref.watch(slProvider);
  return locator<CategoryRepository>();
});
```
