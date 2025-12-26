// lib/src/features/welcome/presentation/providers/bootstrap_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateNotifierProvider;

import 'package:movi/src/core/auth/presentation/providers/auth_providers.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/core/preferences/selected_profile_preferences.dart';
import 'package:movi/src/core/profile/data/repositories/supabase_profile_repository.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/core/startup/app_startup_provider.dart'
    as app_startup_provider;
import 'package:movi/src/core/state/app_event_bus.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/core/logging/logging.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart';
import 'package:movi/src/features/iptv/application/services/xtream_sync_service.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_xtream_catalog.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_stalker_catalog.dart';
import 'package:movi/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart';
import 'package:movi/src/features/iptv/data/services/iptv_credentials_edge_service.dart';

typedef AppLaunchRunner = Future<AppLaunchResult> Function(String reason);

final appLaunchOrchestratorProvider =
    StateNotifierProvider<AppLaunchOrchestrator, AppLaunchState>((ref) {
      final sl = ref.read(slProvider);
      return AppLaunchOrchestrator(
        startupRunner: () =>
            ref.read(app_startup_provider.appStartupProvider.future),
        authRepository: ref.read(authRepositoryProvider),
        profileRepository: sl<SupabaseProfileRepository>(),
        iptvSourcesRepository: sl<SupabaseIptvSourcesRepository>(),
        selectedProfilePreferences: sl<SelectedProfilePreferences>(),
        selectedIptvSourcePreferences: sl<SelectedIptvSourcePreferences>(),
        iptvLocalRepository: sl<IptvLocalRepository>(),
        refreshXtreamCatalog: sl<RefreshXtreamCatalog>(),
        refreshStalkerCatalog: sl<RefreshStalkerCatalog>(),
        xtreamSyncService: sl<XtreamSyncService>(),
        appStateController: ref.read(appStateControllerProvider),
        appEventBus: ref.read(appEventBusProvider),
        homePreload: ref.read(homeControllerProvider.notifier).load,
        launchRegistry: sl<AppLaunchStateRegistry>(),
        credentialsEdgeService:
            sl.isRegistered<IptvCredentialsEdgeService>()
                ? sl<IptvCredentialsEdgeService>()
                : null,
        credentialsVault:
            sl.isRegistered<CredentialsVault>() ? sl<CredentialsVault>() : null,
      );
    });

final appLaunchStateProvider = Provider<AppLaunchState>((ref) {
  return ref.watch(appLaunchOrchestratorProvider);
});

final appLaunchRunnerProvider = Provider<AppLaunchRunner>((ref) {
  return (String reason) async {
    final ts = DateTime.now().toIso8601String();
    unawaited(
      LoggingService.log(
        '[AppLaunch] ts=$ts action=run reason=$reason',
      ),
    );
    return ref.read(appLaunchOrchestratorProvider.notifier).run();
  };
});
