import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/core/auth/domain/entities/auth_failures.dart';
import 'package:movi/src/core/auth/domain/entities/auth_models.dart';
import 'package:movi/src/core/auth/domain/repositories/auth_repository.dart';
import 'package:movi/src/core/config/models/feature_flags.dart';
import 'package:movi/src/core/config/providers/overrides.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/preferences/suppressed_remote_iptv_sources_preferences.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/core/preferences/selected_profile_preferences.dart';
import 'package:movi/src/core/profile/data/repositories/fallback_profile_repository.dart';
import 'package:movi/src/core/profile/data/repositories/local_profile_repository.dart';
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/domain/repositories/profile_repository.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/shared/failure.dart';
import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/core/startup/app_startup_provider.dart'
    as app_startup_provider;
import 'package:movi/src/core/startup/entry_journey_orchestrator.dart';
import 'package:movi/src/core/startup/domain/tunnel_state.dart';
import 'package:movi/src/core/startup/domain/startup_contracts.dart';
import 'package:movi/src/core/supabase/supabase_providers.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/core/storage/database/sqlite_database_migrations.dart';
import 'package:movi/src/core/storage/database/sqlite_database_schema.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/core/utils/result.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart';
import 'package:movi/src/features/library/application/services/comprehensive_cloud_sync_service.dart';
import 'package:movi/src/features/library/application/services/library_cloud_sync_service.dart';
import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_providers.dart';
import 'package:movi/src/features/iptv/application/services/xtream_sync_service.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_stalker_catalog.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_xtream_catalog.dart';
import 'package:movi/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart';
import 'package:movi/src/features/iptv/data/datasources/xtream_cache_data_source.dart';
import 'package:movi/src/features/iptv/data/services/iptv_credentials_edge_service.dart';
import 'package:movi/src/features/iptv/domain/entities/stalker_account.dart';
import 'package:movi/src/features/iptv/domain/entities/stalker_catalog_snapshot.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_catalog_snapshot.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/iptv/domain/repositories/iptv_repository.dart';
import 'package:movi/src/features/iptv/domain/repositories/stalker_repository.dart';
import 'package:movi/src/features/iptv/domain/value_objects/stalker_endpoint.dart';
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/features/welcome/domain/enum.dart';
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await sl.reset();
  });

  test(
    'returns welcomeUser without backend when no local profile exists',
    () async {
      final harness = await _LaunchHarness.create();
      addTearDown(harness.dispose);

      final result = await harness.run();

      expect(result.isSuccess, isTrue);
      expect(result.destination, BootstrapDestination.welcomeUser);
      expect(result.meta.accountId, isNull);
      expect(result.meta.profilesCount, 0);
    },
  );

  test(
    'shadow tunnel reports profileRequired when no local profile exists',
    () async {
      final harness = await _LaunchHarness.create(
        enableEntryJourneyStateModelV2: true,
      );
      addTearDown(harness.dispose);

      final result = await harness.run();
      final shadow = await harness.container.read(
        entryJourneyShadowSnapshotProvider.future,
      );

      expect(result.destination, BootstrapDestination.welcomeUser);
      expect(shadow.canonicalState.stage, TunnelStage.profileRequired);
      expect(shadow.comparison, EntryJourneyShadowComparison.convergent);
    },
  );

  test(
    'emits entry journey telemetry events when v2 telemetry flag is enabled',
    () async {
      final harness = await _LaunchHarness.create(
        enableEntryJourneyTelemetryV2: true,
      );
      addTearDown(harness.dispose);

      await harness.localProfiles.createProfile(
        name: 'Local Profile',
        color: 0xFF2160AB,
      );
      const accountId = 'local_xtream_account_telemetry';
      await harness.iptvLocal.saveAccount(
        XtreamAccount(
          id: accountId,
          alias: 'Offline Source',
          endpoint: XtreamEndpoint.parse('http://example.com'),
          username: 'demo',
          status: XtreamAccountStatus.pending,
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await harness.iptvLocal.savePlaylists(accountId, <XtreamPlaylist>[
        XtreamPlaylist(
          id: 'pl_movies',
          accountId: accountId,
          title: 'Films',
          type: XtreamPlaylistType.movies,
          items: const <XtreamPlaylistItem>[
            XtreamPlaylistItem(
              accountId: accountId,
              categoryId: 'cat_movies',
              categoryName: 'Films',
              streamId: 1001,
              title: 'Film local',
              type: XtreamPlaylistItemType.movie,
              tmdbId: 550,
            ),
          ],
        ),
      ]);

      final result = await harness.run();

      expect(result.destination, BootstrapDestination.home);
      final telemetryEvents = harness.logger.events
          .where((event) => event.category == 'entry_journey')
          .map((event) => event.message)
          .join('\n');
      expect(
        telemetryEvents,
        contains('feature=entry_journey event=entry_journey_started'),
      );
      expect(
        telemetryEvents,
        contains('feature=entry_journey event=entry_journey_stage_entered'),
      );
      expect(
        telemetryEvents,
        contains('feature=entry_journey event=profiles_inventory_loaded'),
      );
      expect(
        telemetryEvents,
        contains('feature=entry_journey event=catalog_minimal_ready'),
      );
      expect(
        telemetryEvents,
        contains('feature=entry_journey event=catalog_full_load_completed'),
      );
      expect(
        telemetryEvents,
        contains('feature=entry_journey event=entry_journey_completed'),
      );
      expect(telemetryEvents, contains('runId='));
    },
  );

  test(
    'does not emit entry journey telemetry events when v2 telemetry flag is disabled',
    () async {
      final harness = await _LaunchHarness.create(
        enableEntryJourneyTelemetryV2: false,
      );
      addTearDown(harness.dispose);

      await harness.localProfiles.createProfile(
        name: 'Local Profile',
        color: 0xFF2160AB,
      );
      const accountId = 'local_xtream_account_no_telemetry';
      await harness.iptvLocal.saveAccount(
        XtreamAccount(
          id: accountId,
          alias: 'Offline Source',
          endpoint: XtreamEndpoint.parse('http://example.com'),
          username: 'demo',
          status: XtreamAccountStatus.pending,
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await harness.iptvLocal.savePlaylists(accountId, <XtreamPlaylist>[
        XtreamPlaylist(
          id: 'pl_movies',
          accountId: accountId,
          title: 'Films',
          type: XtreamPlaylistType.movies,
          items: const <XtreamPlaylistItem>[
            XtreamPlaylistItem(
              accountId: accountId,
              categoryId: 'cat_movies',
              categoryName: 'Films',
              streamId: 1001,
              title: 'Film local',
              type: XtreamPlaylistItemType.movie,
              tmdbId: 550,
            ),
          ],
        ),
      ]);

      final result = await harness.run();

      expect(result.destination, BootstrapDestination.home);
      final telemetryEvents = harness.logger.events
          .where((event) => event.category == 'entry_journey')
          .map((event) => event.message)
          .join('\n');
      expect(telemetryEvents, isEmpty);
    },
  );

  test(
    'emits manual selection safe state telemetry when multiple sources require user choice',
    () async {
      final harness = await _LaunchHarness.create(
        enableEntryJourneyTelemetryV2: true,
      );
      addTearDown(harness.dispose);

      await harness.localProfiles.createProfile(
        name: 'Local Profile',
        color: 0xFF2160AB,
      );

      Future<void> saveSource(String accountId, String title) async {
        await harness.iptvLocal.saveAccount(
          XtreamAccount(
            id: accountId,
            alias: title,
            endpoint: XtreamEndpoint.parse('http://example.com'),
            username: 'demo',
            status: XtreamAccountStatus.pending,
            createdAt: DateTime(2026, 1, 1),
          ),
        );
        await harness.iptvLocal.savePlaylists(accountId, <XtreamPlaylist>[
          XtreamPlaylist(
            id: 'pl_$accountId',
            accountId: accountId,
            title: 'Films',
            type: XtreamPlaylistType.movies,
            items: <XtreamPlaylistItem>[
              XtreamPlaylistItem(
                accountId: accountId,
                categoryId: 'cat_movies',
                categoryName: 'Films',
                streamId: 1001,
                title: 'Film $title',
                type: XtreamPlaylistItemType.movie,
                tmdbId: 550,
              ),
            ],
          ),
        ]);
      }

      await saveSource('source_1', 'Source 1');
      await saveSource('source_2', 'Source 2');

      final result = await harness.run();

      expect(result.destination, BootstrapDestination.chooseSource);
      final telemetryEvents = harness.logger.events
          .where((event) => event.category == 'entry_journey')
          .map((event) => event.message)
          .join('\n');
      expect(
        telemetryEvents,
        contains('event=source_selection_resolved runId='),
      );
      expect(telemetryEvents, contains('result=manual_selection_required'));
      expect(telemetryEvents, contains('reasonCode=source_selection_required'));
      expect(
        telemetryEvents,
        contains('event=entry_journey_safe_state_reached'),
      );
      expect(telemetryEvents, contains('destination=chooseSource'));
    },
  );

  test(
    'shadow tunnel reports authRequired when cloud auth is enabled and no session exists',
    () async {
      final harness = await _LaunchHarness.create(
        cloudAuthEnabled: true,
        enableEntryJourneyStateModelV2: true,
      );
      addTearDown(harness.dispose);

      await harness.localProfiles.createProfile(
        name: 'Local Profile',
        color: 0xFF2160AB,
      );

      final result = await harness.run();
      final shadow = await harness.container.read(
        entryJourneyShadowSnapshotProvider.future,
      );

      expect(result.destination, BootstrapDestination.auth);
      expect(shadow.canonicalState.stage, TunnelStage.authRequired);
      expect(shadow.comparison, EntryJourneyShadowComparison.convergent);
    },
  );

  test(
    'returns auth when cloud auth is enabled and no validated session exists',
    () async {
      final harness = await _LaunchHarness.create(cloudAuthEnabled: true);
      addTearDown(harness.dispose);

      await harness.localProfiles.createProfile(
        name: 'Local Profile',
        color: 0xFF2160AB,
      );
      const accountId = 'local_xtream_account_signed_out';
      await harness.iptvLocal.saveAccount(
        XtreamAccount(
          id: accountId,
          alias: 'Offline Source',
          endpoint: XtreamEndpoint.parse('http://example.com'),
          username: 'demo',
          status: XtreamAccountStatus.pending,
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await harness.iptvLocal.savePlaylists(accountId, <XtreamPlaylist>[
        XtreamPlaylist(
          id: 'pl_movies',
          accountId: accountId,
          title: 'Films',
          type: XtreamPlaylistType.movies,
          items: const <XtreamPlaylistItem>[
            XtreamPlaylistItem(
              accountId: accountId,
              categoryId: 'cat_movies',
              categoryName: 'Films',
              streamId: 1001,
              title: 'Film local',
              type: XtreamPlaylistItemType.movie,
              tmdbId: 550,
            ),
          ],
        ),
      ]);

      final result = await harness.run();

      expect(result.isSuccess, isTrue);
      expect(result.destination, BootstrapDestination.auth);
      expect(result.meta.accountId, isNull);
      expect(harness.authRepository.refreshCalls, 0);
      expect(harness.homeController.loadCalls, 0);
    },
  );

  test(
    'continues local-first when cloud auth refresh fails transiently',
    () async {
      final harness = await _LaunchHarness.create(cloudAuthEnabled: true);
      addTearDown(harness.dispose);

      harness.authRepository.session = const AuthSession(userId: 'cloud-user');
      harness.authRepository.refreshThrows = StateError('refresh failed');

      await harness.localProfiles.createProfile(
        name: 'Cloud Profile',
        color: 0xFF2160AB,
        accountId: 'cloud-user',
      );
      const accountId = 'cloud_xtream_account_refresh_failed';
      await harness.iptvLocal.saveAccount(
        XtreamAccount(
          id: accountId,
          alias: 'Cloud Source',
          endpoint: XtreamEndpoint.parse('http://example.com'),
          username: 'demo',
          status: XtreamAccountStatus.pending,
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await harness.iptvLocal.savePlaylists(accountId, <XtreamPlaylist>[
        XtreamPlaylist(
          id: 'pl_movies',
          accountId: accountId,
          title: 'Films',
          type: XtreamPlaylistType.movies,
          items: const <XtreamPlaylistItem>[
            XtreamPlaylistItem(
              accountId: accountId,
              categoryId: 'cat_movies',
              categoryName: 'Films',
              streamId: 1001,
              title: 'Film local',
              type: XtreamPlaylistItemType.movie,
              tmdbId: 550,
            ),
          ],
        ),
      ]);

      final result = await harness.run();

      expect(result.isSuccess, isTrue);
      expect(result.destination, BootstrapDestination.home);
      expect(result.meta.accountId, isNull);
      expect(harness.authRepository.refreshCalls, 1);
      expect(harness.homeController.loadCalls, 1);
      expect(
        harness.container.read(appLaunchOrchestratorProvider).recovery?.kind,
        AppLaunchRecoveryKind.degradedRetryable,
      );
      expect(
        harness.container.read(appLaunchOrchestratorProvider).recovery?.cause,
        AuthFailureCode.refreshFailed,
      );
    },
  );

  test(
    'shadow tunnel reports authRequired when cloud session requires reauthentication',
    () async {
      final harness = await _LaunchHarness.create(
        cloudAuthEnabled: true,
        enableEntryJourneyStateModelV2: true,
      );
      addTearDown(harness.dispose);

      harness.authRepository.session = const AuthSession(userId: 'cloud-user');
      harness.authRepository.returnNullOnRefresh = true;

      await harness.localProfiles.createProfile(
        name: 'Cloud Profile',
        color: 0xFF2160AB,
        accountId: 'cloud-user',
      );

      final result = await harness.run();
      final shadow = await harness.container.read(
        entryJourneyShadowSnapshotProvider.future,
      );

      expect(result.destination, BootstrapDestination.auth);
      expect(shadow.canonicalState.stage, TunnelStage.authRequired);
      expect(shadow.comparison, EntryJourneyShadowComparison.convergent);
    },
  );

  test(
    'routes invalid cloud sessions to explicit auth reauthentication',
    () async {
      final harness = await _LaunchHarness.create(cloudAuthEnabled: true);
      addTearDown(harness.dispose);

      harness.authRepository.session = const AuthSession(userId: 'cloud-user');
      harness.authRepository.returnNullOnRefresh = true;

      await harness.localProfiles.createProfile(
        name: 'Cloud Profile',
        color: 0xFF2160AB,
        accountId: 'cloud-user',
      );

      final result = await harness.run();

      expect(result.isSuccess, isTrue);
      expect(result.destination, BootstrapDestination.auth);
      expect(result.meta.accountId, isNull);
      expect(harness.authRepository.refreshCalls, 1);
      expect(harness.authRepository.signOutCalls, 1);
      expect(
        harness.container.read(appLaunchOrchestratorProvider).recovery?.kind,
        AppLaunchRecoveryKind.reauthRequired,
      );
      expect(
        harness.container.read(appLaunchOrchestratorProvider).recovery?.cause,
        AuthFailureCode.invalidSession,
      );
    },
  );

  test(
    'continues local-first in degraded retryable mode after auth timeout',
    () async {
      final harness = await _LaunchHarness.create(cloudAuthEnabled: true);
      addTearDown(harness.dispose);

      harness.authRepository.session = const AuthSession(userId: 'cloud-user');
      harness.authRepository.refreshThrows = TimeoutException(
        'auth refresh timeout',
      );

      await harness.localProfiles.createProfile(
        name: 'Offline Profile',
        color: 0xFF2160AB,
      );
      const accountId = 'local_xtream_account_timeout';
      await harness.iptvLocal.saveAccount(
        XtreamAccount(
          id: accountId,
          alias: 'Offline Source',
          endpoint: XtreamEndpoint.parse('http://example.com'),
          username: 'demo',
          status: XtreamAccountStatus.pending,
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await harness.iptvLocal.savePlaylists(accountId, <XtreamPlaylist>[
        XtreamPlaylist(
          id: 'pl_movies',
          accountId: accountId,
          title: 'Films',
          type: XtreamPlaylistType.movies,
          items: const <XtreamPlaylistItem>[
            XtreamPlaylistItem(
              accountId: accountId,
              categoryId: 'cat_movies',
              categoryName: 'Films',
              streamId: 1001,
              title: 'Film local',
              type: XtreamPlaylistItemType.movie,
              tmdbId: 550,
            ),
          ],
        ),
      ]);

      final result = await harness.run();

      expect(result.isSuccess, isTrue);
      expect(result.destination, BootstrapDestination.home);
      expect(result.meta.accountId, isNull);
      expect(
        harness.container.read(appLaunchOrchestratorProvider).recovery?.kind,
        AppLaunchRecoveryKind.degradedRetryable,
      );
      expect(
        harness.container.read(appLaunchOrchestratorProvider).recovery?.cause,
        AuthFailureCode.timeout,
      );
    },
  );

  test(
    'validates the session before entering the authenticated launch path',
    () async {
      final harness = await _LaunchHarness.create(cloudAuthEnabled: true);
      addTearDown(harness.dispose);

      harness.authRepository.session = const AuthSession(userId: 'cloud-user');

      final created = await harness.localProfiles.createProfile(
        name: 'Cloud Profile',
        color: 0xFF2160AB,
        accountId: 'cloud-user',
      );
      const accountId = 'cloud_xtream_account_validated';
      await harness.iptvLocal.saveAccount(
        XtreamAccount(
          id: accountId,
          alias: 'Cloud Source',
          endpoint: XtreamEndpoint.parse('http://example.com'),
          username: 'demo',
          status: XtreamAccountStatus.pending,
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await harness.iptvLocal.savePlaylists(accountId, <XtreamPlaylist>[
        XtreamPlaylist(
          id: 'pl_movies',
          accountId: accountId,
          title: 'Films',
          type: XtreamPlaylistType.movies,
          items: const <XtreamPlaylistItem>[
            XtreamPlaylistItem(
              accountId: accountId,
              categoryId: 'cat_movies',
              categoryName: 'Films',
              streamId: 1001,
              title: 'Film local',
              type: XtreamPlaylistItemType.movie,
              tmdbId: 550,
            ),
          ],
        ),
      ]);

      final result = await harness.run();

      expect(result.isSuccess, isTrue);
      expect(result.destination, BootstrapDestination.home);
      expect(result.meta.accountId, 'cloud-user');
      expect(result.meta.selectedProfileId, created.id);
      expect(harness.authRepository.refreshCalls, 1);
    },
  );

  test(
    'triggers cloud auto-resync in background after authenticated bootstrap',
    () async {
      final harness = await _LaunchHarness.create(
        cloudAuthEnabled: true,
        trackCloudSync: true,
      );
      addTearDown(harness.dispose);

      harness.authRepository.session = const AuthSession(userId: 'cloud-user');

      const cloudProfileId = '11111111-1111-4111-8111-111111111111';
      await harness.localProfiles.upsertProfile(
        Profile(
          id: cloudProfileId,
          accountId: 'cloud-user',
          name: 'Cloud Profile',
          color: 0xFF2160AB,
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await harness.selectedProfilePreferences.setSelectedProfileId(
        cloudProfileId,
      );

      const accountId = 'cloud_xtream_account_auto_sync';
      await harness.iptvLocal.saveAccount(
        XtreamAccount(
          id: accountId,
          alias: 'Cloud Source',
          endpoint: XtreamEndpoint.parse('http://example.com'),
          username: 'demo',
          status: XtreamAccountStatus.pending,
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await harness.iptvLocal.savePlaylists(accountId, <XtreamPlaylist>[
        XtreamPlaylist(
          id: 'pl_movies',
          accountId: accountId,
          title: 'Films',
          type: XtreamPlaylistType.movies,
          items: const <XtreamPlaylistItem>[
            XtreamPlaylistItem(
              accountId: accountId,
              categoryId: 'cat_movies',
              categoryName: 'Films',
              streamId: 1001,
              title: 'Film local',
              type: XtreamPlaylistItemType.movie,
              tmdbId: 550,
            ),
          ],
        ),
      ]);

      final result = await harness.run();
      expect(result.isSuccess, isTrue);
      expect(result.destination, BootstrapDestination.home);

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(harness.trackingCloudSyncService, isNotNull);
      expect(harness.trackingCloudSyncService!.syncAllCalls, 1);
      expect(harness.trackingCloudSyncService!.pullUserPreferencesCalls, 1);
    },
  );

  test(
    'cloud auto-resync failure stays best-effort and does not block home bootstrap',
    () async {
      final harness = await _LaunchHarness.create(
        cloudAuthEnabled: true,
        trackCloudSync: true,
        cloudSyncFailure: StateError('forced cloud sync failure'),
      );
      addTearDown(harness.dispose);

      harness.authRepository.session = const AuthSession(userId: 'cloud-user');

      const cloudProfileId = '22222222-2222-4222-8222-222222222222';
      await harness.localProfiles.upsertProfile(
        Profile(
          id: cloudProfileId,
          accountId: 'cloud-user',
          name: 'Cloud Profile',
          color: 0xFF2160AB,
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await harness.selectedProfilePreferences.setSelectedProfileId(
        cloudProfileId,
      );

      const accountId = 'cloud_xtream_account_auto_sync_failure';
      await harness.iptvLocal.saveAccount(
        XtreamAccount(
          id: accountId,
          alias: 'Cloud Source',
          endpoint: XtreamEndpoint.parse('http://example.com'),
          username: 'demo',
          status: XtreamAccountStatus.pending,
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await harness.iptvLocal.savePlaylists(accountId, <XtreamPlaylist>[
        XtreamPlaylist(
          id: 'pl_movies',
          accountId: accountId,
          title: 'Films',
          type: XtreamPlaylistType.movies,
          items: const <XtreamPlaylistItem>[
            XtreamPlaylistItem(
              accountId: accountId,
              categoryId: 'cat_movies',
              categoryName: 'Films',
              streamId: 1001,
              title: 'Film local',
              type: XtreamPlaylistItemType.movie,
              tmdbId: 550,
            ),
          ],
        ),
      ]);

      final result = await harness.run();
      expect(result.isSuccess, isTrue);
      expect(result.destination, BootstrapDestination.home);

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(harness.trackingCloudSyncService, isNotNull);
      expect(harness.trackingCloudSyncService!.syncAllCalls, 1);
      expect(harness.trackingCloudSyncService!.pullUserPreferencesCalls, 0);
    },
  );

  test(
    'does not rehydrate a remote source suppressed after local deletion',
    () async {
      final secureStorageRepository = _FakeSecureStorageRepository();
      final suppressedPrefs = SuppressedRemoteIptvSourcesPreferences(
        storage: secureStorageRepository,
      );
      await suppressedPrefs.suppress(
        accountId: 'cloud-user',
        localId: 'cloud_local_source',
      );

      final credentialsVault = MemoryCredentialsVault();
      final harness = await _LaunchHarness.create(
        cloudAuthEnabled: true,
        secureStorageRepository: secureStorageRepository,
        credentialsVault: credentialsVault,
        credentialsEdgeService: _FakeIptvCredentialsEdgeService(
          const <String, ({String username, String password})>{
            'v1:encrypted': (username: 'demo', password: 'secret'),
          },
        ),
        iptvSourcesRepository:
            _FakeSupabaseIptvSourcesRepository(<SupabaseIptvSourceEntity>[
              const SupabaseIptvSourceEntity(
                id: 'remote_1',
                accountId: 'cloud-user',
                name: 'Cloud Source',
                localId: 'cloud_local_source',
                serverUrl: 'http://example.com',
                username: 'demo',
                encryptedCredentials: 'v1:encrypted',
              ),
            ]),
      );
      addTearDown(harness.dispose);

      harness.authRepository.session = const AuthSession(userId: 'cloud-user');

      await harness.localProfiles.createProfile(
        name: 'Cloud Profile',
        color: 0xFF2160AB,
        accountId: 'cloud-user',
      );

      final result = await harness.run();

      expect(result.isSuccess, isTrue);
      expect(result.destination, BootstrapDestination.welcomeSources);
      expect(await harness.iptvLocal.getAccounts(), isEmpty);
      expect(
        await suppressedPrefs.readSuppressedLocalIds(accountId: 'cloud-user'),
        {'cloud_local_source'},
      );
      expect(await credentialsVault.readPassword('cloud_local_source'), isNull);
    },
  );

  test(
    'rehydrates a single remote source and preserves it as active before catalog failure',
    () async {
      final credentialsVault = MemoryCredentialsVault();
      final harness = await _LaunchHarness.create(
        cloudAuthEnabled: true,
        credentialsVault: credentialsVault,
        credentialsEdgeService: _FakeIptvCredentialsEdgeService(
          const <String, ({String username, String password})>{
            'v1:encrypted': (username: 'demo', password: 'secret'),
          },
        ),
        iptvSourcesRepository:
            _FakeSupabaseIptvSourcesRepository(<SupabaseIptvSourceEntity>[
              const SupabaseIptvSourceEntity(
                id: 'remote_1',
                accountId: 'cloud-user',
                name: 'Cloud Source',
                localId: 'cloud_local_source',
                serverUrl: 'http://example.com',
                username: 'demo',
                encryptedCredentials: 'v1:encrypted',
              ),
            ]),
      );
      addTearDown(harness.dispose);

      harness.authRepository.session = const AuthSession(userId: 'cloud-user');

      await harness.localProfiles.createProfile(
        name: 'Cloud Profile',
        color: 0xFF2160AB,
        accountId: 'cloud-user',
      );

      final result = await harness.run();

      expect(result.isSuccess, isFalse);
      expect(result.failure, isNotNull);
      expect(
        result.failure!.failure.message.toLowerCase(),
        contains('catalog'),
      );
      final localAccounts = await harness.iptvLocal.getAccounts();
      expect(localAccounts.map((account) => account.id).toList(), [
        'cloud_local_source',
      ]);
      expect(
        harness.selectedSourcePreferences.selectedSourceId,
        'cloud_local_source',
      );
      expect(
        harness.container.read(appStateControllerProvider).activeIptvSourceIds,
        {'cloud_local_source'},
      );
      expect(
        await credentialsVault.readPassword('cloud_local_source'),
        'secret',
      );
    },
  );

  test(
    'clears a stale selected source and routes to chooseSource when multiple local sources remain',
    () async {
      final harness = await _LaunchHarness.create();
      addTearDown(harness.dispose);

      await harness.localProfiles.createProfile(
        name: 'Local Profile',
        color: 0xFF2160AB,
      );

      Future<void> saveSource(String accountId) async {
        await harness.iptvLocal.saveAccount(
          XtreamAccount(
            id: accountId,
            alias: accountId,
            endpoint: XtreamEndpoint.parse('http://example.com'),
            username: 'demo',
            status: XtreamAccountStatus.pending,
            createdAt: DateTime(2026, 1, 1),
          ),
        );
        await harness.iptvLocal.savePlaylists(accountId, <XtreamPlaylist>[
          XtreamPlaylist(
            id: 'pl_$accountId',
            accountId: accountId,
            title: 'Films',
            type: XtreamPlaylistType.movies,
            items: <XtreamPlaylistItem>[
              XtreamPlaylistItem(
                accountId: accountId,
                categoryId: 'cat_movies',
                categoryName: 'Films',
                streamId: 1001,
                title: 'Film $accountId',
                type: XtreamPlaylistItemType.movie,
                tmdbId: 550,
              ),
            ],
          ),
        ]);
      }

      await saveSource('source_1');
      await saveSource('source_2');
      await harness.selectedSourcePreferences.setSelectedSourceId(
        'stale_source',
      );

      final result = await harness.run();

      expect(result.isSuccess, isTrue);
      expect(result.destination, BootstrapDestination.chooseSource);
      expect(harness.selectedSourcePreferences.selectedSourceId, isNull);
      expect(harness.homeController.loadCalls, 0);
    },
  );

  test(
    'returns welcomeSources without backend when local profile exists but no local source exists',
    () async {
      final harness = await _LaunchHarness.create();
      addTearDown(harness.dispose);

      final created = await harness.localProfiles.createProfile(
        name: 'Local Profile',
        color: 0xFF2160AB,
      );

      final result = await harness.run();

      expect(result.isSuccess, isTrue);
      expect(result.destination, BootstrapDestination.welcomeSources);
      expect(result.meta.profilesCount, 1);
      expect(harness.selectedProfilePreferences.selectedProfileId, created.id);
    },
  );

  test(
    'shadow tunnel reports sourceRequired when multiple sources need manual selection',
    () async {
      final harness = await _LaunchHarness.create(
        enableEntryJourneyStateModelV2: true,
      );
      addTearDown(harness.dispose);

      await harness.localProfiles.createProfile(
        name: 'Local Profile',
        color: 0xFF2160AB,
      );

      Future<void> saveSource(String accountId) async {
        await harness.iptvLocal.saveAccount(
          XtreamAccount(
            id: accountId,
            alias: accountId,
            endpoint: XtreamEndpoint.parse('http://example.com'),
            username: 'demo',
            status: XtreamAccountStatus.pending,
            createdAt: DateTime(2026, 1, 1),
          ),
        );
        await harness.iptvLocal.savePlaylists(accountId, <XtreamPlaylist>[
          XtreamPlaylist(
            id: 'pl_$accountId',
            accountId: accountId,
            title: 'Films',
            type: XtreamPlaylistType.movies,
            items: <XtreamPlaylistItem>[
              XtreamPlaylistItem(
                accountId: accountId,
                categoryId: 'cat_movies',
                categoryName: 'Films',
                streamId: 1001,
                title: 'Film $accountId',
                type: XtreamPlaylistItemType.movie,
                tmdbId: 550,
              ),
            ],
          ),
        ]);
      }

      await saveSource('source_1');
      await saveSource('source_2');

      final result = await harness.run();
      final shadow = await harness.container.read(
        entryJourneyShadowSnapshotProvider.future,
      );

      expect(result.destination, BootstrapDestination.chooseSource);
      expect(shadow.canonicalState.stage, TunnelStage.sourceRequired);
      expect(shadow.comparison, EntryJourneyShadowComparison.convergent);
    },
  );

  test(
    'returns home without backend when local profile and local IPTV source exist',
    () async {
      final harness = await _LaunchHarness.create(
        enableEntryJourneyStateModelV2: true,
      );
      addTearDown(harness.dispose);

      final created = await harness.localProfiles.createProfile(
        name: 'Offline Profile',
        color: 0xFF2160AB,
      );
      const accountId = 'local_xtream_account';
      await harness.iptvLocal.saveAccount(
        XtreamAccount(
          id: accountId,
          alias: 'Offline Source',
          endpoint: XtreamEndpoint.parse('http://example.com'),
          username: 'demo',
          status: XtreamAccountStatus.pending,
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await harness.iptvLocal.savePlaylists(accountId, <XtreamPlaylist>[
        XtreamPlaylist(
          id: 'pl_movies',
          accountId: accountId,
          title: 'Films',
          type: XtreamPlaylistType.movies,
          items: const <XtreamPlaylistItem>[
            XtreamPlaylistItem(
              accountId: accountId,
              categoryId: 'cat_movies',
              categoryName: 'Films',
              streamId: 1001,
              title: 'Film local',
              type: XtreamPlaylistItemType.movie,
              tmdbId: 550,
            ),
          ],
        ),
      ]);

      final result = await harness.run();

      expect(result.isSuccess, isTrue);
      expect(result.destination, BootstrapDestination.home);
      expect(result.meta.profilesCount, 1);
      expect(result.meta.localAccountsCount, 1);
      expect(result.meta.selectedProfileId, created.id);
      expect(result.meta.selectedSourceId, accountId);
      expect(harness.selectedProfilePreferences.selectedProfileId, created.id);
      expect(harness.selectedSourcePreferences.selectedSourceId, accountId);
      expect(harness.homeController.loadCalls, 1);
      // Bootstrap progress stage should be cleared after preload.
      expect(
        harness.container.read(homeBootstrapProgressStageProvider),
        isNull,
      );
      expect(
        harness.container.read(appStateControllerProvider).activeIptvSourceIds,
        {accountId},
      );
      expect(
        harness.container
            .read(appLaunchOrchestratorProvider)
            .criteria
            .isHomeReady,
        isTrue,
      );

      final shadow = await harness.container.read(
        entryJourneyShadowSnapshotProvider.future,
      );
      expect(shadow.canonicalState.stage, TunnelStage.readyForHome);
      expect(shadow.comparison, EntryJourneyShadowComparison.convergent);
    },
  );

  test('fails launch when IPTV catalog is not ready before home', () async {
    final harness = await _LaunchHarness.create();
    addTearDown(harness.dispose);

    await harness.localProfiles.createProfile(
      name: 'Offline Profile',
      color: 0xFF2160AB,
    );
    const accountId = 'local_xtream_account_without_playlist';
    await harness.iptvLocal.saveAccount(
      XtreamAccount(
        id: accountId,
        alias: 'Offline Source',
        endpoint: XtreamEndpoint.parse('http://example.com'),
        username: 'demo',
        status: XtreamAccountStatus.pending,
        createdAt: DateTime(2026, 1, 1),
      ),
    );

    final result = await harness.run();

    expect(result.isSuccess, isFalse);
    expect(result.failure, isNotNull);
    expect(result.failure!.failure.message.toLowerCase(), contains('catalog'));
  });

  test('run is idempotent when called concurrently', () async {
    final harness = await _LaunchHarness.create();
    addTearDown(harness.dispose);

    await harness.localProfiles.createProfile(
      name: 'Offline Profile',
      color: 0xFF2160AB,
    );
    const accountId = 'local_xtream_account_concurrent';
    await harness.iptvLocal.saveAccount(
      XtreamAccount(
        id: accountId,
        alias: 'Offline Source',
        endpoint: XtreamEndpoint.parse('http://example.com'),
        username: 'demo',
        status: XtreamAccountStatus.pending,
        createdAt: DateTime(2026, 1, 1),
      ),
    );
    await harness.iptvLocal.savePlaylists(accountId, <XtreamPlaylist>[
      XtreamPlaylist(
        id: 'pl_movies',
        accountId: accountId,
        title: 'Films',
        type: XtreamPlaylistType.movies,
        items: const <XtreamPlaylistItem>[
          XtreamPlaylistItem(
            accountId: accountId,
            categoryId: 'cat_movies',
            categoryName: 'Films',
            streamId: 1001,
            title: 'Film local',
            type: XtreamPlaylistItemType.movie,
            tmdbId: 550,
          ),
        ],
      ),
    ]);

    final orchestrator = harness.container.read(
      appLaunchOrchestratorProvider.notifier,
    );
    final futureA = orchestrator.run();
    final futureB = orchestrator.run();
    expect(identical(futureA, futureB), isTrue);

    final results = await Future.wait([futureA, futureB]);
    expect(results.first.isSuccess, isTrue);
    expect(results.last.isSuccess, isTrue);
    expect(harness.homeController.loadCalls, 1);
  });

  test(
    'succeeds when bootstrap preload is already inflight before preload step',
    () async {
      final harness = await _LaunchHarness.create();
      addTearDown(harness.dispose);

      await harness.localProfiles.createProfile(
        name: 'Offline Profile',
        color: 0xFF2160AB,
      );
      const accountId = 'local_xtream_account_inflight';
      await harness.iptvLocal.saveAccount(
        XtreamAccount(
          id: accountId,
          alias: 'Offline Source',
          endpoint: XtreamEndpoint.parse('http://example.com'),
          username: 'demo',
          status: XtreamAccountStatus.pending,
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await harness.iptvLocal.savePlaylists(accountId, <XtreamPlaylist>[
        XtreamPlaylist(
          id: 'pl_movies',
          accountId: accountId,
          title: 'Films',
          type: XtreamPlaylistType.movies,
          items: const <XtreamPlaylistItem>[
            XtreamPlaylistItem(
              accountId: accountId,
              categoryId: 'cat_movies',
              categoryName: 'Films',
              streamId: 1001,
              title: 'Film local',
              type: XtreamPlaylistItemType.movie,
              tmdbId: 550,
            ),
          ],
        ),
      ]);

      harness.homeController.simulateExternalBootstrapPreload(
        delay: const Duration(milliseconds: 40),
      );

      final result = await harness.run();

      expect(result.isSuccess, isTrue);
      expect(harness.homeController.bootstrapPreloadExecutions, 1);
      expect(harness.homeController.preloadLoadCalls, 0);
    },
  );

  test('retries home preload on transient invalid state', () async {
    final harness = await _LaunchHarness.create();
    addTearDown(harness.dispose);

    await harness.localProfiles.createProfile(
      name: 'Offline Profile',
      color: 0xFF2160AB,
    );
    const accountId = 'local_xtream_account_retry_home_preload';
    await harness.iptvLocal.saveAccount(
      XtreamAccount(
        id: accountId,
        alias: 'Offline Source',
        endpoint: XtreamEndpoint.parse('http://example.com'),
        username: 'demo',
        status: XtreamAccountStatus.pending,
        createdAt: DateTime(2026, 1, 1),
      ),
    );
    await harness.iptvLocal.savePlaylists(accountId, <XtreamPlaylist>[
      XtreamPlaylist(
        id: 'pl_movies',
        accountId: accountId,
        title: 'Films',
        type: XtreamPlaylistType.movies,
        items: const <XtreamPlaylistItem>[
          XtreamPlaylistItem(
            accountId: accountId,
            categoryId: 'cat_movies',
            categoryName: 'Films',
            streamId: 1001,
            title: 'Film local',
            type: XtreamPlaylistItemType.movie,
            tmdbId: 550,
          ),
        ],
      ),
    ]);

    harness.homeController.transientPreloadFailures = 1;
    final result = await harness.run();

    expect(result.isSuccess, isTrue);
    expect(harness.homeController.preloadLoadCalls, greaterThanOrEqualTo(2));
  });
}

class _LaunchHarness {
  _LaunchHarness._({
    required this.db,
    required this.container,
    required this.localProfiles,
    required this.iptvLocal,
    required this.selectedProfilePreferences,
    required this.selectedSourcePreferences,
    required this.localePreferences,
    required this.authRepository,
    required this.homeController,
    required this.logger,
    this.trackingCloudSyncService,
    this.supabaseClient,
  });

  final Database db;
  final ProviderContainer container;
  final LocalProfileRepository localProfiles;
  final IptvLocalRepository iptvLocal;
  final _MemorySelectedProfilePreferences selectedProfilePreferences;
  final _MemorySelectedIptvSourcePreferences selectedSourcePreferences;
  final _MemoryLocalePreferences localePreferences;
  final _FakeAuthRepository authRepository;
  final _FakeHomeController homeController;
  final _MemoryLogger logger;
  final _TrackingComprehensiveCloudSyncService? trackingCloudSyncService;
  final SupabaseClient? supabaseClient;

  static Future<_LaunchHarness> create({
    bool cloudAuthEnabled = false,
    bool enableEntryJourneyTelemetryV2 = false,
    bool enableEntryJourneyStateModelV2 = false,
    bool trackCloudSync = false,
    Object? cloudSyncFailure,
    SecureStorageRepository? secureStorageRepository,
    CredentialsVault? credentialsVault,
    IptvCredentialsEdgeService? credentialsEdgeService,
    SupabaseIptvSourcesRepository? iptvSourcesRepository,
  }) async {
    await sl.reset();

    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 18,
      onCreate: (database, version) async {
        await LocalDatabaseSchema.create(database, version);
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        await LocalDatabaseMigrations.upgrade(database, oldVersion, newVersion);
      },
    );

    final localePreferences = _MemoryLocalePreferences();
    final selectedProfilePreferences = _MemorySelectedProfilePreferences();
    final selectedSourcePreferences = _MemorySelectedIptvSourcePreferences();
    final authRepository = _FakeAuthRepository();
    final localProfiles = LocalProfileRepository(db);
    final iptvLocal = IptvLocalRepository(db);
    final contentCache = ContentCacheRepository(db);
    final logger = _MemoryLogger();
    final refreshXtreamCatalog = _FakeRefreshXtreamCatalog();
    final refreshStalkerCatalog = _FakeRefreshStalkerCatalog();
    final homeController = _FakeHomeController();
    final trackingCloudSyncService = trackCloudSync
        ? _TrackingComprehensiveCloudSyncService(
            db: db,
            forcedFailure: cloudSyncFailure,
          )
        : null;
    final supabaseClient = cloudAuthEnabled
        ? SupabaseClient('https://example.supabase.co', 'anon-key')
        : null;
    supabaseClient?.auth.stopAutoRefresh();

    sl.registerSingleton<Database>(db);
    sl.registerSingleton<AppLogger>(logger);
    sl.registerSingleton<LocalePreferences>(localePreferences);
    sl.registerSingleton<SelectedProfilePreferences>(
      selectedProfilePreferences,
    );
    sl.registerSingleton<SelectedIptvSourcePreferences>(
      selectedSourcePreferences,
    );
    sl.registerSingleton<AuthRepository>(authRepository);
    sl.registerSingleton<LocalProfileRepository>(localProfiles);
    sl.registerSingleton<ProfileRepository>(
      FallbackProfileRepository(local: localProfiles, auth: authRepository),
    );
    sl.registerSingleton<IptvLocalRepository>(iptvLocal);
    sl.registerSingleton<AppLaunchStateRegistry>(AppLaunchStateRegistry());
    sl.registerSingleton<TunnelStateRegistry>(TunnelStateRegistry());
    sl.registerSingleton<RefreshXtreamCatalog>(refreshXtreamCatalog);
    sl.registerSingleton<RefreshStalkerCatalog>(refreshStalkerCatalog);
    if (secureStorageRepository != null) {
      sl.registerSingleton<SecureStorageRepository>(secureStorageRepository);
    }
    if (credentialsVault != null) {
      sl.registerSingleton<CredentialsVault>(credentialsVault);
    }
    if (credentialsEdgeService != null) {
      sl.registerSingleton<IptvCredentialsEdgeService>(credentialsEdgeService);
    }
    if (iptvSourcesRepository != null) {
      sl.registerSingleton<SupabaseIptvSourcesRepository>(
        iptvSourcesRepository,
      );
    }

    final container = ProviderContainer(
      overrides: [
        overrideFeatureFlags(
          FeatureFlags(
            enableTelemetry: true,
            enableEntryJourneyTelemetryV2: enableEntryJourneyTelemetryV2,
            enableEntryJourneyStateModelV2: enableEntryJourneyStateModelV2,
          ),
        ),
        cloudAuthEnabledProvider.overrideWith((ref) => cloudAuthEnabled),
        app_startup_provider.appStartupProvider.overrideWith(
          (ref) async => StartupResult.ready(durationMs: 0),
        ),
        homeControllerProvider.overrideWith(() => homeController),
        if (trackingCloudSyncService != null)
          comprehensiveCloudSyncServiceProvider.overrideWithValue(
            trackingCloudSyncService,
          ),
        if (supabaseClient != null)
          supabaseClientProvider.overrideWithValue(supabaseClient),
      ],
    );

    final appStateController = container.read(appStateControllerProvider);
    sl.registerSingleton<XtreamSyncService>(
      _NoopXtreamSyncService(
        appStateController,
        refreshXtreamCatalog,
        XtreamCacheDataSource(contentCache),
        logger,
      ),
    );

    return _LaunchHarness._(
      db: db,
      container: container,
      localProfiles: localProfiles,
      iptvLocal: iptvLocal,
      selectedProfilePreferences: selectedProfilePreferences,
      selectedSourcePreferences: selectedSourcePreferences,
      localePreferences: localePreferences,
      authRepository: authRepository,
      homeController: homeController,
      logger: logger,
      trackingCloudSyncService: trackingCloudSyncService,
      supabaseClient: supabaseClient,
    );
  }

  Future<AppLaunchResult> run() {
    return container.read(appLaunchOrchestratorProvider.notifier).run();
  }

  Future<void> dispose() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    container.dispose();
    await db.close();
    await localePreferences.dispose();
    await selectedProfilePreferences.dispose();
    await selectedSourcePreferences.dispose();
    authRepository.dispose();
  }
}

class _FakeHomeController extends HomeController {
  int loadCalls = 0;
  int preloadLoadCalls = 0;
  int bootstrapPreloadExecutions = 0;
  int transientPreloadFailures = 0;
  bool _externalBootstrapPreloadInFlight = false;
  Completer<void>? _externalBootstrapPreloadCompleter;

  @override
  HomeState build() => const HomeState();

  @override
  Future<void> load({
    bool awaitIptv = false,
    String reason = 'unknown',
    bool force = false,
    Duration? cooldown,
  }) async {
    if (reason == 'preload') {
      preloadLoadCalls += 1;
      bootstrapPreloadExecutions += 1;
      if (transientPreloadFailures > 0) {
        transientPreloadFailures -= 1;
        loadCalls += 1;
        state = const HomeState(
          isLoading: false,
          isHeroEmpty: false,
          error: 'transient preload state',
        );
        return;
      }
    }
    loadCalls += 1;
    state = HomeState(
      iptvLists: <String, List<ContentReference>>{
        'Nouveautes': <ContentReference>[
          ContentReference(
            id: '1',
            title: MediaTitle('Film test'),
            type: ContentType.movie,
          ),
        ],
      },
      isLoading: false,
      isHeroEmpty: false,
    );
  }

  @override
  bool get bootstrapPreloadInFlight =>
      _externalBootstrapPreloadInFlight || super.bootstrapPreloadInFlight;

  @override
  Future<void> waitForBootstrapPreloadCompletion() async {
    if (_externalBootstrapPreloadInFlight) {
      await _externalBootstrapPreloadCompleter?.future;
      state = HomeState(
        iptvLists: <String, List<ContentReference>>{
          'Nouveautes': <ContentReference>[
            ContentReference(
              id: '1',
              title: MediaTitle('Film test'),
              type: ContentType.movie,
            ),
          ],
        },
        isLoading: false,
        isHeroEmpty: false,
      );
    }
    await super.waitForBootstrapPreloadCompletion();
  }

  void simulateExternalBootstrapPreload({Duration delay = Duration.zero}) {
    if (_externalBootstrapPreloadInFlight) return;
    _externalBootstrapPreloadInFlight = true;
    bootstrapPreloadExecutions += 1;
    _externalBootstrapPreloadCompleter = Completer<void>();
    unawaited(
      Future<void>.delayed(delay, () {
        _externalBootstrapPreloadInFlight = false;
        final completer = _externalBootstrapPreloadCompleter;
        if (completer != null && !completer.isCompleted) {
          completer.complete();
        }
      }),
    );
  }
}

class _FakeAuthRepository implements AuthRepository {
  final StreamController<AuthSnapshot> _controller =
      StreamController<AuthSnapshot>.broadcast();

  AuthSession? _session;
  int refreshCalls = 0;
  int signOutCalls = 0;
  Object? refreshThrows;
  Duration? refreshDelay;
  bool returnNullOnRefresh = false;

  @override
  Stream<AuthSnapshot> get onAuthStateChange => _controller.stream;

  @override
  AuthSession? get currentSession => _session;

  set session(AuthSession? value) {
    _session = value;
  }

  @override
  Future<AuthSession?> refreshSession() async {
    refreshCalls += 1;
    final delay = refreshDelay;
    if (delay != null) {
      await Future<void>.delayed(delay);
    }
    final failure = refreshThrows;
    if (failure != null) throw failure;
    if (returnNullOnRefresh) return null;
    return _session;
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    _session = const AuthSession(userId: 'test-user');
    _controller.add(
      AuthSnapshot(status: AuthStatus.authenticated, session: _session),
    );
  }

  @override
  Future<void> signInWithOtp({
    required String email,
    bool shouldCreateUser = true,
  }) async {}

  @override
  Future<bool> verifyOtp({required String email, required String token}) async {
    _session = const AuthSession(userId: 'test-user');
    _controller.add(
      AuthSnapshot(status: AuthStatus.authenticated, session: _session),
    );
    return true;
  }

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
    _session = null;
    _controller.add(AuthSnapshot.unauthenticated);
  }

  void dispose() {
    _controller.close();
  }
}

class _MemoryLogger implements AppLogger {
  final List<LogEvent> events = <LogEvent>[];

  @override
  void debug(String message, {String? category}) {
    log(LogLevel.debug, message, category: category);
  }

  @override
  void info(String message, {String? category}) {
    log(LogLevel.info, message, category: category);
  }

  @override
  void warn(String message, {String? category}) {
    log(LogLevel.warn, message, category: category);
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    log(LogLevel.error, message, error: error, stackTrace: stackTrace);
  }

  @override
  void log(
    LogLevel level,
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {
    events.add(
      LogEvent(
        timestamp: DateTime.now(),
        level: level,
        message: message,
        category: category,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}

class _MemoryLocalePreferences implements LocalePreferences {
  final StreamController<String> _languageController =
      StreamController<String>.broadcast();
  final StreamController<ThemeMode> _themeController =
      StreamController<ThemeMode>.broadcast();

  String _languageCode = 'en-US';
  ThemeMode _themeMode = ThemeMode.system;

  @override
  String get languageCode => _languageCode;

  @override
  Stream<String> get languageStream => _languageController.stream;

  @override
  Stream<String> get languageStreamWithInitial async* {
    yield _languageCode;
    yield* _languageController.stream;
  }

  @override
  ThemeMode get themeMode => _themeMode;

  @override
  Stream<ThemeMode> get themeStream => _themeController.stream;

  @override
  Stream<ThemeMode> get themeStreamWithInitial async* {
    yield _themeMode;
    yield* _themeController.stream;
  }

  @override
  Future<void> setLanguageCode(String code) async {
    _languageCode = code;
    _languageController.add(code);
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    _themeController.add(mode);
  }

  @override
  Future<void> dispose() async {
    await _languageController.close();
    await _themeController.close();
  }
}

class _MemorySelectedProfilePreferences implements SelectedProfilePreferences {
  final StreamController<String?> _controller =
      StreamController<String?>.broadcast();
  String? _selectedProfileId;

  @override
  String? get selectedProfileId => _selectedProfileId;

  @override
  Stream<String?> get selectedProfileIdStream => _controller.stream;

  @override
  Stream<String?> get selectedProfileIdStreamWithInitial async* {
    yield _selectedProfileId;
    yield* _controller.stream;
  }

  @override
  Future<void> setSelectedProfileId(String? profileId) async {
    _selectedProfileId = profileId?.trim().isEmpty == true
        ? null
        : profileId?.trim();
    _controller.add(_selectedProfileId);
  }

  @override
  Future<void> clear() => setSelectedProfileId(null);

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

class _MemorySelectedIptvSourcePreferences
    implements SelectedIptvSourcePreferences {
  final StreamController<String?> _controller =
      StreamController<String?>.broadcast();
  String? _selectedSourceId;

  @override
  String? get selectedSourceId => _selectedSourceId;

  @override
  Stream<String?> get selectedSourceIdStream => _controller.stream;

  @override
  Stream<String?> get selectedSourceIdStreamWithInitial async* {
    yield _selectedSourceId;
    yield* _controller.stream;
  }

  @override
  Future<void> setSelectedSourceId(String? sourceId) async {
    _selectedSourceId = sourceId?.trim().isEmpty == true
        ? null
        : sourceId?.trim();
    _controller.add(_selectedSourceId);
  }

  @override
  Future<void> rereadFromStorage() async {}

  @override
  Future<void> clear() => setSelectedSourceId(null);

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

class _FakeRefreshXtreamCatalog extends RefreshXtreamCatalog {
  _FakeRefreshXtreamCatalog() : super(_FakeIptvRepository());

  @override
  Future<Result<XtreamCatalogSnapshot, Failure>> call(String accountId) async {
    return Ok(
      XtreamCatalogSnapshot(
        accountId: accountId,
        lastSyncAt: DateTime.now(),
        movieCount: 0,
        seriesCount: 0,
      ),
    );
  }
}

class _FakeRefreshStalkerCatalog extends RefreshStalkerCatalog {
  _FakeRefreshStalkerCatalog() : super(_FakeStalkerRepository());

  @override
  Future<Result<StalkerCatalogSnapshot, Failure>> call(String accountId) async {
    return Ok(
      StalkerCatalogSnapshot(
        accountId: accountId,
        lastSyncAt: DateTime.now(),
        movieCount: 0,
        seriesCount: 0,
      ),
    );
  }
}

class _NoopXtreamSyncService extends XtreamSyncService {
  _NoopXtreamSyncService(super.state, super.refresh, super.cache, super.logger);

  @override
  void start({
    bool skipInitialIfFresh = true,
    DateTime? initialRefreshAt,
    Duration? initialCooldown,
    String reason = 'service',
  }) {}

  @override
  void stop() {}
}

class _FakeIptvRepository implements IptvRepository {
  @override
  Future<XtreamAccount> addSource({
    required XtreamEndpoint endpoint,
    required String username,
    required String password,
    required String alias,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<XtreamPlaylist>> listPlaylists(String accountId) async {
    return const <XtreamPlaylist>[];
  }

  @override
  Future<XtreamCatalogSnapshot> refreshCatalog(String accountId) async {
    return XtreamCatalogSnapshot(
      accountId: accountId,
      lastSyncAt: DateTime.now(),
      movieCount: 0,
      seriesCount: 0,
    );
  }
}

class _FakeStalkerRepository implements StalkerRepository {
  @override
  Future<StalkerAccount> addSource({
    required StalkerEndpoint endpoint,
    required String macAddress,
    String? username,
    String? password,
    required String alias,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<XtreamPlaylist>> listPlaylists(String accountId) async {
    return const <XtreamPlaylist>[];
  }

  @override
  Future<StalkerCatalogSnapshot> refreshCatalog(String accountId) async {
    return StalkerCatalogSnapshot(
      accountId: accountId,
      lastSyncAt: DateTime.now(),
      movieCount: 0,
      seriesCount: 0,
    );
  }
}

final class _TrackingComprehensiveCloudSyncService
    extends ComprehensiveCloudSyncService {
  _TrackingComprehensiveCloudSyncService({
    required Database db,
    this.forcedFailure,
  }) : super(
         sl: GetIt.asNewInstance(),
         librarySync: LibraryCloudSyncService(
           secureStorage: _MemorySecurePayloadStore(),
           outbox: SyncOutboxRepository(db),
           db: db,
           playlistLocal: PlaylistLocalRepository(db: db),
         ),
       );

  final Object? forcedFailure;
  int syncAllCalls = 0;
  int pullUserPreferencesCalls = 0;

  @override
  Future<void> syncAll({
    required SupabaseClient client,
    required String profileId,
    bool Function()? shouldCancel,
  }) async {
    syncAllCalls += 1;
    final failure = forcedFailure;
    if (failure != null) {
      throw failure;
    }
  }

  @override
  Future<void> pullUserPreferences({
    required SupabaseClient client,
    bool Function()? shouldCancel,
    Set<String>? knownIptvAccountIds,
    bool preferLocalAccent = false,
    String context = 'default',
  }) async {
    pullUserPreferencesCalls += 1;
  }
}

final class _MemorySecurePayloadStore implements SecurePayloadStore {
  final Map<String, Map<String, dynamic>> _data =
      <String, Map<String, dynamic>>{};

  @override
  Future<Map<String, dynamic>?> get(String key) async {
    final value = _data[key];
    if (value == null) return null;
    return Map<String, dynamic>.from(value);
  }

  @override
  Future<void> put({
    required String key,
    required Map<String, dynamic> payload,
  }) async {
    _data[key] = Map<String, dynamic>.from(payload);
  }

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }
}

final class _FakeSecureStorageRepository extends SecureStorageRepository {
  _FakeSecureStorageRepository();

  final Map<String, Map<String, dynamic>> _store =
      <String, Map<String, dynamic>>{};

  @override
  Future<Map<String, dynamic>?> get(String key) async {
    final value = _store[key];
    if (value == null) {
      return null;
    }
    return Map<String, dynamic>.from(value);
  }

  @override
  Future<void> put({
    required String key,
    required Map<String, dynamic> payload,
  }) async {
    _store[key] = Map<String, dynamic>.from(payload);
  }

  @override
  Future<void> remove(String key) async {
    _store.remove(key);
  }
}

final class _FakeIptvCredentialsEdgeService extends IptvCredentialsEdgeService {
  _FakeIptvCredentialsEdgeService(this._payloads)
    : super(SupabaseClient('https://example.supabase.co', 'anon-key'));

  final Map<String, ({String username, String password})> _payloads;

  @override
  Future<({String username, String password})> decrypt({
    required String ciphertext,
  }) async {
    final payload = _payloads[ciphertext];
    if (payload == null) {
      throw FormatException('Missing fake credentials payload for $ciphertext');
    }
    return payload;
  }
}

final class _FakeSupabaseIptvSourcesRepository
    extends SupabaseIptvSourcesRepository {
  _FakeSupabaseIptvSourcesRepository(this.sources)
    : super(SupabaseClient('https://example.supabase.co', 'anon-key'));

  final List<SupabaseIptvSourceEntity> sources;

  @override
  Future<List<SupabaseIptvSourceEntity>> getSources({
    String? accountId,
    bool? diagnostics,
  }) async {
    return sources;
  }
}
