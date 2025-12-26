import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:movi/src/core/auth/domain/repositories/auth_repository.dart';
import 'package:movi/src/core/logging/logging.dart';
import 'package:movi/src/core/profile/data/repositories/supabase_profile_repository.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/security/iptv_credentials_cipher.dart';
import 'package:movi/src/core/shared/failure.dart';
import 'package:movi/src/core/state/app_event_bus.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/core/preferences/selected_profile_preferences.dart';
import 'package:movi/src/core/startup/app_launch_criteria.dart';
import 'package:movi/src/features/iptv/application/services/xtream_sync_service.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_xtream_catalog.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_stalker_catalog.dart';
import 'package:movi/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart';
import 'package:movi/src/features/iptv/data/services/iptv_credentials_edge_service.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';
import 'package:movi/src/features/welcome/domain/enum.dart';
import 'package:state_notifier/state_notifier.dart';

typedef AppStartupRunner = Future<void> Function();
typedef HomePreloadRunner = Future<void> Function({
  required bool awaitIptv,
  String reason,
  bool force,
  Duration? cooldown,
});

enum AppLaunchStatus { idle, running, success, failure }

enum AppLaunchPhase {
  init,
  startup,
  auth,
  profiles,
  sources,
  localAccounts,
  sourceSelection,
  preloadMinimalHome,
  done,
}

class AppLaunchState {
  const AppLaunchState({
    this.status = AppLaunchStatus.idle,
    this.phase = AppLaunchPhase.init,
    this.error,
    this.startedAt,
    this.completedAt,
    this.destination,
    this.criteria = AppLaunchCriteria.empty,
  });

  final AppLaunchStatus status;
  final AppLaunchPhase phase;
  final AppLaunchFailure? error;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final BootstrapDestination? destination;
  final AppLaunchCriteria criteria;

  static const _sentinel = Object();

  AppLaunchState copyWith({
    AppLaunchStatus? status,
    AppLaunchPhase? phase,
    Object? error = _sentinel,
    Object? startedAt = _sentinel,
    Object? completedAt = _sentinel,
    Object? destination = _sentinel,
    AppLaunchCriteria? criteria,
  }) {
    return AppLaunchState(
      status: status ?? this.status,
      phase: phase ?? this.phase,
      error: identical(error, _sentinel) ? this.error : error as AppLaunchFailure?,
      startedAt: identical(startedAt, _sentinel)
          ? this.startedAt
          : startedAt as DateTime?,
      completedAt: identical(completedAt, _sentinel)
          ? this.completedAt
          : completedAt as DateTime?,
      destination: identical(destination, _sentinel)
          ? this.destination
          : destination as BootstrapDestination?,
      criteria: criteria ?? this.criteria,
    );
  }
}

class AppLaunchStateRegistry extends ChangeNotifier {
  AppLaunchStateRegistry({AppLaunchState? initial})
      : _state = initial ?? const AppLaunchState();

  AppLaunchState _state;

  AppLaunchState get state => _state;

  void update(AppLaunchState next) {
    _state = next;
    notifyListeners();
  }
}

class AppLaunchFailure {
  const AppLaunchFailure({
    required this.step,
    required this.failure,
    required this.original,
    this.userId,
  });

  final String step;
  final Failure failure;
  final Object original;
  final String? userId;
}

class AppLaunchMeta {
  const AppLaunchMeta({
    this.accountId,
    this.profilesCount,
    this.sourcesCount,
    this.localAccountsCount,
    this.selectedProfileId,
    this.selectedSourceId,
    this.iptvCatalogReady = false,
  });

  final String? accountId;
  final int? profilesCount;
  final int? sourcesCount;
  final int? localAccountsCount;
  final String? selectedProfileId;
  final String? selectedSourceId;
  final bool iptvCatalogReady;

  AppLaunchMeta copyWith({
    String? accountId,
    int? profilesCount,
    int? sourcesCount,
    int? localAccountsCount,
    String? selectedProfileId,
    String? selectedSourceId,
    bool? iptvCatalogReady,
  }) {
    return AppLaunchMeta(
      accountId: accountId ?? this.accountId,
      profilesCount: profilesCount ?? this.profilesCount,
      sourcesCount: sourcesCount ?? this.sourcesCount,
      localAccountsCount: localAccountsCount ?? this.localAccountsCount,
      selectedProfileId: selectedProfileId ?? this.selectedProfileId,
      selectedSourceId: selectedSourceId ?? this.selectedSourceId,
      iptvCatalogReady: iptvCatalogReady ?? this.iptvCatalogReady,
    );
  }
}

class AppLaunchResult {
  const AppLaunchResult({
    required this.destination,
    required this.meta,
    this.failure,
  });

  final BootstrapDestination destination;
  final AppLaunchMeta meta;
  final AppLaunchFailure? failure;

  bool get isSuccess => failure == null;
}

class _IptvPreloadResult {
  const _IptvPreloadResult({
    required this.catalogReady,
    required this.refreshed,
  });

  final bool catalogReady;
  final bool refreshed;
}

class AppLaunchOrchestrator extends StateNotifier<AppLaunchState> {
  AppLaunchOrchestrator({
    required AppStartupRunner startupRunner,
    required AuthRepository authRepository,
    required SupabaseProfileRepository profileRepository,
    required SupabaseIptvSourcesRepository iptvSourcesRepository,
    required SelectedProfilePreferences selectedProfilePreferences,
    required SelectedIptvSourcePreferences selectedIptvSourcePreferences,
    required IptvLocalRepository iptvLocalRepository,
    required RefreshXtreamCatalog refreshXtreamCatalog,
    required RefreshStalkerCatalog refreshStalkerCatalog,
    required XtreamSyncService xtreamSyncService,
    required AppStateController appStateController,
    required AppEventBus appEventBus,
    required HomePreloadRunner homePreload,
    required AppLaunchStateRegistry launchRegistry,
    IptvCredentialsEdgeService? credentialsEdgeService,
    CredentialsVault? credentialsVault,
  })  : _startupRunner = startupRunner,
        _authRepository = authRepository,
        _profileRepository = profileRepository,
        _iptvSourcesRepository = iptvSourcesRepository,
        _selectedProfilePreferences = selectedProfilePreferences,
        _selectedIptvSourcePreferences = selectedIptvSourcePreferences,
        _iptvLocalRepository = iptvLocalRepository,
        _refreshXtreamCatalog = refreshXtreamCatalog,
        _refreshStalkerCatalog = refreshStalkerCatalog,
        _xtreamSyncService = xtreamSyncService,
        _appStateController = appStateController,
        _appEventBus = appEventBus,
        _homePreload = homePreload,
        _launchRegistry = launchRegistry,
        _credentialsEdgeService = credentialsEdgeService,
        _credentialsVault = credentialsVault,
        super(const AppLaunchState()) {
    _launchRegistry.update(state);
  }

  final AppStartupRunner _startupRunner;
  final AuthRepository _authRepository;
  final SupabaseProfileRepository _profileRepository;
  final SupabaseIptvSourcesRepository _iptvSourcesRepository;
  final SelectedProfilePreferences _selectedProfilePreferences;
  final SelectedIptvSourcePreferences _selectedIptvSourcePreferences;
  final IptvLocalRepository _iptvLocalRepository;
  final RefreshXtreamCatalog _refreshXtreamCatalog;
  final RefreshStalkerCatalog _refreshStalkerCatalog;
  final XtreamSyncService _xtreamSyncService;
  final AppStateController _appStateController;
  final AppEventBus _appEventBus;
  final HomePreloadRunner _homePreload;
  final AppLaunchStateRegistry _launchRegistry;
  final IptvCredentialsEdgeService? _credentialsEdgeService;
  final CredentialsVault? _credentialsVault;

  Future<AppLaunchResult>? _ongoing;
  Future<void>? _backgroundSync;

  void _updateState(AppLaunchState next) {
    state = next;
    _launchRegistry.update(next);
  }

  Future<AppLaunchResult> run() {
    final current = _ongoing;
    if (current != null) return current;

    final startedAt = DateTime.now();
    _updateState(state.copyWith(
      status: AppLaunchStatus.running,
      phase: AppLaunchPhase.init,
      error: null,
      startedAt: startedAt,
      completedAt: null,
      destination: null,
      criteria: AppLaunchCriteria.empty,
    ));
    _logPhase(
      AppLaunchPhase.init,
      AppLaunchStatus.running,
      stepName: 'start',
    );

    final future = _runInternal();
    _ongoing = future;
    future.whenComplete(() {
      if (_ongoing == future) {
        _ongoing = null;
      }
    });
    return future;
  }

  void reset() {
    _ongoing = null;
    _backgroundSync = null;
    _updateState(const AppLaunchState());
  }

  @override
  void dispose() {
    _xtreamSyncService.stop();
    super.dispose();
  }

  Future<AppLaunchResult> _runInternal() async {
    var step = 'init';
    var destination = BootstrapDestination.auth;
    var meta = const AppLaunchMeta();

    void updateCriteria() {
      _updateState(state.copyWith(
        criteria: AppLaunchCriteria.fromIds(
          accountId: meta.accountId,
          selectedProfileId: meta.selectedProfileId,
          selectedSourceId: meta.selectedSourceId,
        ),
      ));
    }

    Future<void> logStep(String message) async {
      final uid = meta.accountId ?? 'null';
      final pc = meta.profilesCount?.toString() ?? 'n/a';
      final sc = meta.sourcesCount?.toString() ?? 'n/a';
      final lc = meta.localAccountsCount?.toString() ?? 'n/a';
      final selProfile = meta.selectedProfileId ?? 'n/a';
      final selSource = meta.selectedSourceId ?? 'n/a';
      final dest = destination.name;

      await LoggingService.log(
        '[Preload] step=$step uid=$uid profiles=$pc sources=$sc local=$lc '
        'selectedProfile=$selProfile selectedSource=$selSource dest=$dest :: $message',
      );
    }

    AppLaunchResult completeSuccess(BootstrapDestination nextDestination) {
      destination = nextDestination;
      _updateState(state.copyWith(
        status: AppLaunchStatus.success,
        phase: AppLaunchPhase.done,
        completedAt: DateTime.now(),
        error: null,
        destination: destination,
      ));
      _logPhase(AppLaunchPhase.done, AppLaunchStatus.success, stepName: 'done');
      return AppLaunchResult(destination: destination, meta: meta);
    }

    AppLaunchResult completeFailure(
      Object error,
      StackTrace st,
    ) {
      final failure = Failure.fromException(
        error,
        stackTrace: st,
        code: 'app_launch',
        context: {
          'step': step,
          'userId': meta.accountId,
        },
      );

      final launchFailure = AppLaunchFailure(
        step: step,
        failure: failure,
        original: error,
        userId: meta.accountId,
      );

      unawaited(
        LoggingService.log(
          '[Preload][ERROR] step=$step uid=${meta.accountId ?? 'null'} '
          'type=${error.runtimeType} msg=$error',
        ),
      );

      _updateState(state.copyWith(
        status: AppLaunchStatus.failure,
        error: launchFailure,
        completedAt: DateTime.now(),
        destination: null,
      ));
      _logPhase(
        AppLaunchPhase.done,
        AppLaunchStatus.failure,
        stepName: 'failed',
      );

      return AppLaunchResult(
        destination: BootstrapDestination.auth,
        meta: meta,
        failure: launchFailure,
      );
    }

    try {
      step = 'startup';
      _setPhase(AppLaunchPhase.startup, stepName: step);
      await _startupRunner();
      await logStep('startup done');

      step = 'auth_session';
      _setPhase(AppLaunchPhase.auth, stepName: step);
      final session = _authRepository.currentSession;
      if (session == null) {
        destination = BootstrapDestination.auth;
        await logStep('no session -> auth');
        return completeSuccess(destination);
      }
      meta = meta.copyWith(accountId: session.userId);
      updateCriteria();
      await logStep('session ok');

      step = 'profiles_fetch';
      _setPhase(AppLaunchPhase.profiles, stepName: step);
      final profiles = await _profileRepository.getProfiles(
        accountId: meta.accountId,
      );
      meta = meta.copyWith(profilesCount: profiles.length);
      await logStep('profiles fetched');

      if (profiles.isEmpty) {
        destination = BootstrapDestination.welcomeUser;
        await logStep(
          'profiles empty -> welcomeUser (REAL EMPTY if fetch succeeded)',
        );
        return completeSuccess(destination);
      }

      step = 'profiles_select';
      var selectedProfileId = _selectedProfilePreferences.selectedProfileId;
      final validSelected = profiles.any((p) => p.id == selectedProfileId);
      meta = meta.copyWith(selectedProfileId: selectedProfileId);
      updateCriteria();
      await logStep('selected valid=$validSelected');

      if (!validSelected) {
        await _selectedProfilePreferences.setSelectedProfileId(
          profiles.first.id,
        );
        selectedProfileId = profiles.first.id;
        meta = meta.copyWith(selectedProfileId: selectedProfileId);
        updateCriteria();
        await logStep('selected profile repaired');
      }

      step = 'sources_fetch';
      _setPhase(AppLaunchPhase.sources, stepName: step);
      final supaSources = await _iptvSourcesRepository.getSources(
        accountId: meta.accountId,
      );
      meta = meta.copyWith(sourcesCount: supaSources.length);
      await logStep('sources fetched');

      if (supaSources.isEmpty) {
        destination = BootstrapDestination.welcomeSources;
        await logStep(
          'sources empty -> welcomeSources (REAL EMPTY if fetch succeeded)',
        );
        return completeSuccess(destination);
      }

      unawaited(
        _migrateLegacySupabaseCredentialsToEdge(
          accountId: meta.accountId,
          sources: supaSources,
        ),
      );

      step = 'local_accounts_fetch';
      _setPhase(AppLaunchPhase.localAccounts, stepName: step);
      var localAccounts = await _iptvLocalRepository.getAccounts();
      var localStalkerAccounts =
          await _iptvLocalRepository.getStalkerAccounts();
      var totalLocalCount =
          localAccounts.length + localStalkerAccounts.length;
      meta = meta.copyWith(localAccountsCount: totalLocalCount);
      await logStep(
        'local accounts fetched (xtream=${localAccounts.length} '
        'stalker=${localStalkerAccounts.length})',
      );

      if (localAccounts.isEmpty && localStalkerAccounts.isEmpty) {
        step = 'local_accounts_hydrate_from_supabase';
        final hydrated = await _hydrateLocalAccountsFromSupabase(
          accountId: meta.accountId,
          sources: supaSources,
        );
        await logStep('local hydrated=$hydrated');

        final refreshed = await _iptvLocalRepository.getAccounts();
        localAccounts = refreshed;
        localStalkerAccounts =
            await _iptvLocalRepository.getStalkerAccounts();
        totalLocalCount = refreshed.length + localStalkerAccounts.length;
        meta = meta.copyWith(localAccountsCount: totalLocalCount);
        await logStep(
          'local accounts refetched (xtream=${refreshed.length} '
          'stalker=${localStalkerAccounts.length})',
        );

        if (refreshed.isEmpty && localStalkerAccounts.isEmpty) {
          destination = BootstrapDestination.welcomeSources;
          await logStep('local accounts still empty -> welcomeSources');
          return completeSuccess(destination);
        }
      }

      step = 'iptv_source_selection';
      _setPhase(AppLaunchPhase.sourceSelection, stepName: step);
      final validIds = {
        ...localAccounts.map((a) => a.id),
        ...localStalkerAccounts.map((a) => a.id),
      };
      final preferred = _selectedIptvSourcePreferences.selectedSourceId;
      if (kDebugMode) {
        debugPrint(
          '[BOOTSTRAP] Preferred source present=${preferred != null} '
          'validIds=${validIds.length}',
        );
      }

      if (validIds.length == 1) {
        final onlyId = validIds.first;
        meta = meta.copyWith(selectedSourceId: onlyId);
        updateCriteria();
        if (preferred != onlyId) {
          await _selectedIptvSourcePreferences.setSelectedSourceId(onlyId);
          _appStateController.setActiveIptvSources({onlyId});
          await logStep('single source selected -> $onlyId');
        } else {
          _appStateController.setActiveIptvSources({onlyId});
          await logStep('single source already selected -> $onlyId');
        }
      } else if (preferred != null && validIds.contains(preferred.trim())) {
        final trimmed = preferred.trim();
        meta = meta.copyWith(selectedSourceId: trimmed);
        updateCriteria();
        _appStateController.setActiveIptvSources({trimmed});
        await logStep('selected source restored -> $trimmed');
      } else {
        await _selectedIptvSourcePreferences.clear();
        destination = BootstrapDestination.chooseSource;
        await logStep('multiple sources + no valid selection -> chooseSource');
        return completeSuccess(destination);
      }

      step = 'preload_minimal_home';
      _setPhase(AppLaunchPhase.preloadMinimalHome, stepName: step);

      // TOUJOURS attendre le chargement complet du catalogue IPTV
      // pour garantir l'affichage des tendances et playlists au lancement
      await _homePreload(
        awaitIptv: true, // Toujours attendre le chargement IPTV
        reason: 'preload',
        force: true,
        cooldown: Duration.zero,
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          debugPrint('[Preload] Home load timeout after 45s (continuing)');
        },
      ).catchError((e, st) {
        if (kDebugMode) {
          debugPrint('[Bootstrap] home.load failed (ignored): $e\n$st');
        }
        return null;
      });

      // Attendre un délai supplémentaire pour garantir que toutes les données
      // sont complètement chargées et disponibles dans le state
      await Future.delayed(const Duration(seconds: 2));

      await logStep('home preload done');

      destination = BootstrapDestination.home;
      await logStep('minimal done -> home');
      final result = completeSuccess(destination);

      _startIptvBackgroundSync(meta);
      return result;
    } catch (e, st) {
      return completeFailure(e, st);
    }
  }

  void _setPhase(AppLaunchPhase phase, {String? stepName}) {
    _updateState(state.copyWith(phase: phase));
    _logPhase(phase, state.status, stepName: stepName);
  }

  void _logPhase(
    AppLaunchPhase phase,
    AppLaunchStatus status, {
    String? stepName,
  }) {
    final ts = DateTime.now().toIso8601String();
    final step = stepName ?? phase.name;
    unawaited(
      LoggingService.log(
        '[Launch] ts=$ts phase=${phase.name} status=${status.name} step=$step',
      ),
    );
  }

  void _logIptvSyncDecision({
    required String reason,
    required String action,
    String? detail,
  }) {
    final ts = DateTime.now().toIso8601String();
    final extra = detail == null ? '' : ' detail=$detail';
    unawaited(
      LoggingService.log(
        '[IptvSync] ts=$ts reason=$reason action=$action$extra',
      ),
    );
  }

  Future<_IptvPreloadResult> _ensureIptvCatalogReady({
    String reason = 'preload',
  }) async {
    final activeIds = _appStateController.activeIptvSourceIds;
    if (activeIds.isEmpty) {
      _logIptvSyncDecision(
        reason: reason,
        action: 'skip',
        detail: 'no_active_sources',
      );
      return const _IptvPreloadResult(catalogReady: false, refreshed: false);
    }

    final xtreamAccounts = await _iptvLocalRepository.getAccounts();
    final stalkerAccounts = await _iptvLocalRepository.getStalkerAccounts();

    final xtreamIds = xtreamAccounts.map((a) => a.id).toSet();
    final stalkerIds = stalkerAccounts.map((a) => a.id).toSet();

    var needsRefresh = false;
    for (final id in activeIds) {
      final playlists = await _iptvLocalRepository.getPlaylists(id, itemLimit: 0);
      if (playlists.isEmpty) {
        needsRefresh = true;
        break;
      }
    }

    if (!needsRefresh) {
      final hasAny = await _iptvLocalRepository.hasAnyPlaylistItems(
        accountIds: activeIds,
      );
      if (hasAny) {
        _logIptvSyncDecision(
          reason: reason,
          action: 'skip',
          detail: 'fresh_snapshot',
        );
        return const _IptvPreloadResult(
          catalogReady: true,
          refreshed: false,
        );
      }
    }

    _logIptvSyncDecision(
      reason: reason,
      action: 'run',
      detail: 'refresh_needed',
    );

    var refreshed = false;
    for (final id in activeIds) {
      try {
        if (xtreamIds.contains(id)) {
          if (kDebugMode) {
            debugPrint('[BOOTSTRAP] Refresh Xtream');
          }
          await _refreshXtreamCatalog(id);
          refreshed = true;
        } else if (stalkerIds.contains(id)) {
          if (kDebugMode) {
            debugPrint('[BOOTSTRAP] Refresh Stalker');
          }
          final result = await _refreshStalkerCatalog(id);
          result.fold(
            ok: (snapshot) {
              if (kDebugMode) {
                debugPrint('[BOOTSTRAP] Stalker refresh OK');
                debugPrint(
                  '[BOOTSTRAP] Films: ${snapshot.movieCount}, '
                  'Series: ${snapshot.seriesCount}',
                );
              }
            },
            err: (error) {
              if (kDebugMode) {
                debugPrint('[BOOTSTRAP] Stalker refresh error: $error');
              }
            },
          );
          refreshed = true;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[BOOTSTRAP] Refresh error: $e');
        }
      }
    }

    final nowHasAny = await _iptvLocalRepository.hasAnyPlaylistItems(
      accountIds: activeIds,
    );
    if (kDebugMode) {
      debugPrint('[BOOTSTRAP] hasAnyPlaylistItems: $nowHasAny');
    }

    if (!nowHasAny) {
      _logIptvSyncDecision(
        reason: reason,
        action: 'run',
        detail: 'refresh_failed',
      );
      return const _IptvPreloadResult(catalogReady: false, refreshed: false);
    }

    _logIptvSyncDecision(
      reason: reason,
      action: 'run',
      detail: 'refresh_done',
    );
    _appEventBus.emit(const AppEvent(AppEventType.iptvSynced));
    return _IptvPreloadResult(catalogReady: true, refreshed: refreshed);
  }

  Future<void> _runIptvBackgroundSync(AppLaunchMeta meta) async {
    const step = 'iptv_sync_background';
    await LoggingService.log(
      '[Preload] step=$step uid=${meta.accountId ?? 'null'} :: start',
    );

    final result = await _ensureIptvCatalogReady(
      reason: 'background',
    ).timeout(
      const Duration(seconds: 18),
      onTimeout: () {
        debugPrint('[Preload] IPTV sync timeout after 18s (background)');
        return const _IptvPreloadResult(
          catalogReady: false,
          refreshed: false,
        );
      },
    ).catchError((e) {
      unawaited(
        LoggingService.log(
          '[Preload][WARN] step=$step uid=${meta.accountId} '
          'type=${e.runtimeType}',
        ),
      );
      debugPrint('[Bootstrap] iptv sync failed (background): $e');
      return const _IptvPreloadResult(
        catalogReady: false,
        refreshed: false,
      );
    });

    _xtreamSyncService.start(
      skipInitialIfFresh: true,
      initialRefreshAt: result.refreshed ? DateTime.now() : null,
      reason: 'background',
    );

    if (result.catalogReady) {
      await LoggingService.log(
        '[Preload] step=$step uid=${meta.accountId ?? 'null'} '
        ':: catalog ready',
      );
    } else {
      await LoggingService.log(
        '[Preload] step=$step uid=${meta.accountId ?? 'null'} '
        ':: catalog not ready',
      );
    }
  }

  void _startIptvBackgroundSync(AppLaunchMeta meta) {
    if (_backgroundSync != null) return;
    final future = _runIptvBackgroundSync(meta);
    _backgroundSync = future;
    future.whenComplete(() {
      if (_backgroundSync == future) {
        _backgroundSync = null;
      }
    });
  }

  Future<int> _hydrateLocalAccountsFromSupabase({
    required String? accountId,
    required List<SupabaseIptvSourceEntity> sources,
  }) async {
    final uid = accountId?.trim();
    if (uid == null || uid.isEmpty) return 0;
    if (sources.isEmpty) return 0;

    final edge = _credentialsEdgeService;
    final vault = _credentialsVault;
    if (edge == null || vault == null) return 0;

    var hydrated = 0;
    for (final s in sources) {
      final serverUrl = s.serverUrl?.trim();
      final username = s.username?.trim();
      final ciphertext = s.encryptedCredentials?.trim();

      if (serverUrl == null ||
          serverUrl.isEmpty ||
          username == null ||
          username.isEmpty ||
          ciphertext == null ||
          ciphertext.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[Bootstrap] Skipping source ${s.id}: missing data '
            '(serverUrl=${serverUrl?.isEmpty == false}, '
            'username=${username?.isEmpty == false}, '
            'ciphertext=${ciphertext?.isEmpty == false})',
          );
        }
        continue;
      }

      if (kDebugMode) {
        debugPrint(
          '[Bootstrap] Attempting to parse serverUrl for source ${s.id}: '
          '"$serverUrl"',
        );
      }

      final endpoint = XtreamEndpoint.tryParse(serverUrl);
      if (endpoint == null) {
        if (kDebugMode) {
          debugPrint(
            '[Bootstrap] Failed to parse serverUrl for source ${s.id}: '
            '"$serverUrl" (invalid format)',
          );
        }
        continue;
      }

      try {
        final payload = await edge.decrypt(ciphertext: ciphertext);
        final pw = payload.password;
        if (pw.trim().isEmpty) continue;

        final localId =
            (s.localId?.trim().isNotEmpty ?? false)
                ? s.localId!.trim()
                : '${endpoint.host}_${payload.username}'.toLowerCase();

        final account = XtreamAccount(
          id: localId,
          alias: (s.name.trim().isNotEmpty) ? s.name.trim() : endpoint.host,
          endpoint: endpoint,
          username: payload.username.trim(),
          status: XtreamAccountStatus.pending,
          createdAt: DateTime.now(),
          expirationDate: s.expiresAt,
          lastError: null,
        );

        await _iptvLocalRepository.saveAccount(account);
        await vault.storePassword(localId, pw);
        hydrated += 1;
      } catch (_) {
        // best-effort
      }
    }

    return hydrated;
  }

  Future<void> _migrateLegacySupabaseCredentialsToEdge({
    required String? accountId,
    required List<SupabaseIptvSourceEntity> sources,
  }) async {
    final uid = accountId?.trim();
    if (uid == null || uid.isEmpty) return;
    if (sources.isEmpty) return;

    final edge = _credentialsEdgeService;
    final vault = _credentialsVault;
    if (edge == null || vault == null) return;

    final localCipher = IptvCredentialsCipher(vault);

    try {
      await localCipher.initialize(uid);
    } catch (_) {
      return;
    }

    for (final s in sources) {
      final ciphertext = s.encryptedCredentials?.trim();
      if (ciphertext == null || ciphertext.isEmpty) continue;
      if (ciphertext.startsWith('v1:')) continue;

      try {
        final payload = await localCipher.decryptCredentials(ciphertext);
        final nextCipher = await edge.encrypt(
          username: payload.username,
          password: payload.password,
        );

        await _iptvSourcesRepository.updateSource(
          id: s.id,
          accountId: uid,
          encryptedCredentials: nextCipher,
        );
      } catch (_) {
        // best-effort
      }
    }
  }
}
