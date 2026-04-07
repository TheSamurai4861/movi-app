import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/auth/domain/entities/auth_failures.dart';
import 'package:movi/src/core/auth/domain/entities/auth_models.dart';
import 'package:movi/src/core/config/config.dart';
import 'package:movi/src/core/auth/presentation/providers/auth_providers.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logging.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/core/preferences/selected_profile_preferences.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/security/iptv_credentials_cipher.dart';
import 'package:movi/src/core/shared/failure.dart';
import 'package:movi/src/core/state/app_event_bus.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/core/startup/app_launch_criteria.dart';
import 'package:movi/src/core/startup/app_startup_provider.dart'
    as app_startup_provider;
import 'package:movi/src/core/startup/canonical_tunnel_state_projector.dart';
import 'package:movi/src/core/startup/domain/tunnel_state.dart';
import 'package:movi/src/core/startup/entry_journey_shadow_bridge.dart';
import 'package:movi/src/core/startup/entry_journey_telemetry.dart';
import 'package:movi/src/core/profile/domain/repositories/profile_repository.dart';
import 'package:movi/src/core/supabase/supabase_providers.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart';
import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_providers.dart';
import 'package:movi/src/features/iptv/application/services/xtream_sync_service.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_xtream_catalog.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_stalker_catalog.dart';
import 'package:movi/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart';
import 'package:movi/src/features/iptv/data/services/iptv_credentials_edge_service.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';
import 'package:movi/src/features/welcome/domain/enum.dart';

typedef AppStartupRunner = Future<void> Function();
typedef HomePreloadRunner =
    Future<void> Function({
      required bool awaitIptv,
      String reason,
      bool force,
      Duration? cooldown,
    });

enum AppLaunchStatus { idle, running, success, failure }

enum AppLaunchErrorCode {
  invalidTransition,
  iptvEmptyData,
  iptvNetworkTimeout,
  iptvProviderError,
  homePreloadInvalidState,
  libraryPreloadTimeout,
}

enum AppLaunchPhase {
  init,
  startup,
  auth,
  profiles,
  sources,
  localAccounts,
  sourceSelection,
  preloadCompleteHome,
  done,
}

enum AppLaunchRecoveryKind { reauthRequired, degradedRetryable }

@immutable
class AppLaunchRecovery {
  const AppLaunchRecovery({
    required this.kind,
    required this.cause,
    required this.reasonCode,
    required this.message,
  });

  final AppLaunchRecoveryKind kind;
  final AuthFailureCode cause;
  final String reasonCode;
  final String message;

  bool get isRetryable => kind == AppLaunchRecoveryKind.degradedRetryable;
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
    this.recovery,
    this.recoveryMessage,
    this.runId,
  });

  final AppLaunchStatus status;
  final AppLaunchPhase phase;
  final AppLaunchFailure? error;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final BootstrapDestination? destination;
  final AppLaunchCriteria criteria;
  final AppLaunchRecovery? recovery;
  final String? recoveryMessage;
  final String? runId;

  static const _sentinel = Object();

  AppLaunchState copyWith({
    AppLaunchStatus? status,
    AppLaunchPhase? phase,
    Object? error = _sentinel,
    Object? startedAt = _sentinel,
    Object? completedAt = _sentinel,
    Object? destination = _sentinel,
    AppLaunchCriteria? criteria,
    Object? recovery = _sentinel,
    Object? recoveryMessage = _sentinel,
    Object? runId = _sentinel,
  }) {
    return AppLaunchState(
      status: status ?? this.status,
      phase: phase ?? this.phase,
      error: identical(error, _sentinel)
          ? this.error
          : error as AppLaunchFailure?,
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
      recovery: identical(recovery, _sentinel)
          ? this.recovery
          : recovery as AppLaunchRecovery?,
      recoveryMessage: identical(recoveryMessage, _sentinel)
          ? this.recoveryMessage
          : recoveryMessage as String?,
      runId: identical(runId, _sentinel) ? this.runId : runId as String?,
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
    this.homePreloaded = false,
    this.libraryReady = false,
  });

  final String? accountId;
  final int? profilesCount;
  final int? sourcesCount;
  final int? localAccountsCount;
  final String? selectedProfileId;
  final String? selectedSourceId;
  final bool iptvCatalogReady;
  final bool homePreloaded;
  final bool libraryReady;

  AppLaunchMeta copyWith({
    String? accountId,
    int? profilesCount,
    int? sourcesCount,
    int? localAccountsCount,
    String? selectedProfileId,
    String? selectedSourceId,
    bool? iptvCatalogReady,
    bool? homePreloaded,
    bool? libraryReady,
  }) {
    return AppLaunchMeta(
      accountId: accountId ?? this.accountId,
      profilesCount: profilesCount ?? this.profilesCount,
      sourcesCount: sourcesCount ?? this.sourcesCount,
      localAccountsCount: localAccountsCount ?? this.localAccountsCount,
      selectedProfileId: selectedProfileId ?? this.selectedProfileId,
      selectedSourceId: selectedSourceId ?? this.selectedSourceId,
      iptvCatalogReady: iptvCatalogReady ?? this.iptvCatalogReady,
      homePreloaded: homePreloaded ?? this.homePreloaded,
      libraryReady: libraryReady ?? this.libraryReady,
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

class _LaunchStepException implements Exception {
  const _LaunchStepException(this.code, this.message);

  final AppLaunchErrorCode code;
  final String message;

  @override
  String toString() =>
      'LaunchStepException(code: ${code.name}, message: $message)';
}

class AppLaunchOrchestrator extends Notifier<AppLaunchState> {
  AppLaunchOrchestrator();

  static const Map<AppLaunchPhase, Set<AppLaunchPhase>>
  _allowedPhaseTransitions = <AppLaunchPhase, Set<AppLaunchPhase>>{
    AppLaunchPhase.init: <AppLaunchPhase>{AppLaunchPhase.startup},
    AppLaunchPhase.startup: <AppLaunchPhase>{
      AppLaunchPhase.auth,
      AppLaunchPhase.done,
    },
    AppLaunchPhase.auth: <AppLaunchPhase>{
      AppLaunchPhase.profiles,
      AppLaunchPhase.done,
    },
    AppLaunchPhase.profiles: <AppLaunchPhase>{
      AppLaunchPhase.localAccounts,
      AppLaunchPhase.done,
    },
    AppLaunchPhase.localAccounts: <AppLaunchPhase>{
      AppLaunchPhase.sources,
      AppLaunchPhase.sourceSelection,
      AppLaunchPhase.done,
    },
    AppLaunchPhase.sources: <AppLaunchPhase>{
      AppLaunchPhase.localAccounts,
      AppLaunchPhase.sourceSelection,
      AppLaunchPhase.done,
    },
    AppLaunchPhase.sourceSelection: <AppLaunchPhase>{
      AppLaunchPhase.preloadCompleteHome,
      AppLaunchPhase.done,
    },
    AppLaunchPhase.preloadCompleteHome: <AppLaunchPhase>{AppLaunchPhase.done},
    AppLaunchPhase.done: <AppLaunchPhase>{},
  };

  late final AppStartupRunner _startupRunner;
  late final ProfileRepository _profileRepository;
  late final SupabaseIptvSourcesRepository? _iptvSourcesRepository;
  late final SelectedProfilePreferences _selectedProfilePreferences;
  late final SelectedIptvSourcePreferences _selectedIptvSourcePreferences;
  late final IptvLocalRepository _iptvLocalRepository;
  late final RefreshXtreamCatalog _refreshXtreamCatalog;
  late final RefreshStalkerCatalog _refreshStalkerCatalog;
  late final XtreamSyncService _xtreamSyncService;
  late final AppStateController _appStateController;
  late final AppEventBus _appEventBus;
  late final HomeController _homeController;
  late final HomePreloadRunner _homePreload;
  late final AppLaunchStateRegistry _launchRegistry;
  late final TunnelStateRegistry _tunnelStateRegistry;
  late final IptvCredentialsEdgeService? _credentialsEdgeService;
  late final CredentialsVault? _credentialsVault;
  late final EntryJourneyTelemetry _entryJourneyTelemetry;
  late final LegacyTunnelStateBridge _legacyTunnelStateBridge;
  late final CanonicalTunnelStateProjector _canonicalTunnelStateProjector;
  late final bool _useCanonicalTunnelStateModel;

  Future<AppLaunchResult>? _ongoing;
  Future<void>? _backgroundSync;

  @override
  AppLaunchState build() {
    final sl = ref.read(slProvider);

    _startupRunner = () =>
        ref.read(app_startup_provider.appStartupProvider.future);
    _profileRepository = sl<ProfileRepository>();
    _iptvSourcesRepository = sl.isRegistered<SupabaseIptvSourcesRepository>()
        ? sl<SupabaseIptvSourcesRepository>()
        : null;
    _selectedProfilePreferences = sl<SelectedProfilePreferences>();
    _selectedIptvSourcePreferences = sl<SelectedIptvSourcePreferences>();
    _iptvLocalRepository = sl<IptvLocalRepository>();
    _refreshXtreamCatalog = sl<RefreshXtreamCatalog>();
    _refreshStalkerCatalog = sl<RefreshStalkerCatalog>();
    _xtreamSyncService = sl<XtreamSyncService>();
    _appStateController = ref.read(appStateControllerProvider);
    _appEventBus = ref.read(appEventBusProvider);
    _homeController = ref.read(homeControllerProvider.notifier);
    _homePreload = _homeController.load;
    _launchRegistry = sl<AppLaunchStateRegistry>();
    _tunnelStateRegistry = sl<TunnelStateRegistry>();
    _credentialsEdgeService = sl.isRegistered<IptvCredentialsEdgeService>()
        ? sl<IptvCredentialsEdgeService>()
        : null;
    _credentialsVault = sl.isRegistered<CredentialsVault>()
        ? sl<CredentialsVault>()
        : null;
    var entryJourneyTelemetryEnabled = false;
    try {
      final flags = ref.read(featureFlagsProvider);
      entryJourneyTelemetryEnabled =
          flags.enableTelemetry && flags.enableEntryJourneyTelemetryV2;
      _useCanonicalTunnelStateModel = flags.enableEntryJourneyStateModelV2;
    } catch (_) {
      entryJourneyTelemetryEnabled = false;
      _useCanonicalTunnelStateModel = false;
    }
    _legacyTunnelStateBridge = const LegacyTunnelStateBridge();
    _canonicalTunnelStateProjector = const CanonicalTunnelStateProjector();
    _entryJourneyTelemetry = EntryJourneyTelemetry(
      enabled: entryJourneyTelemetryEnabled,
    );

    ref.onDispose(_xtreamSyncService.stop);

    const initialState = AppLaunchState();
    _launchRegistry.update(initialState);
    _tunnelStateRegistry.update(_projectTunnelState(initialState));
    return initialState;
  }

  void _updateState(AppLaunchState next) {
    state = next;
    _launchRegistry.update(next);
    _tunnelStateRegistry.update(_projectTunnelState(next));
  }

  TunnelState _projectTunnelState(AppLaunchState launchState) {
    if (_useCanonicalTunnelStateModel) {
      return _canonicalTunnelStateProjector.fromLaunchState(launchState);
    }
    return _legacyTunnelStateBridge.fromLaunchState(launchState);
  }

  Future<AppLaunchResult> run() {
    final current = _ongoing;
    if (current != null) return current;

    final startedAt = DateTime.now();
    final runId = startedAt.microsecondsSinceEpoch.toString();
    _updateState(
      state.copyWith(
        status: AppLaunchStatus.running,
        phase: AppLaunchPhase.init,
        error: null,
        startedAt: startedAt,
        completedAt: null,
        destination: null,
        criteria: AppLaunchCriteria.empty,
        recovery: null,
        recoveryMessage: null,
        runId: runId,
      ),
    );
    _logPhase(
      AppLaunchPhase.init,
      AppLaunchStatus.running,
      stepName: 'start',
      runId: runId,
    );
    _entryJourneyTelemetry.event(
      name: 'entry_journey_started',
      runId: runId,
      result: 'start',
      phase: AppLaunchPhase.init.name,
      step: 'run',
      elapsedMs: 0,
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

  void setResolvedDestination(
    BootstrapDestination destination, {
    AppLaunchCriteria? criteria,
  }) {
    _updateState(
      state.copyWith(
        status: AppLaunchStatus.success,
        phase: AppLaunchPhase.done,
        completedAt: DateTime.now(),
        error: null,
        destination: destination,
        criteria: criteria,
      ),
    );
  }

  /// Termine le tunnel d'entrée après un chargement manuel de source
  /// (ex: ajout d'une première source depuis l'écran de bienvenue).
  ///
  /// Ce chemin ne repasse pas par [run()], car l'utilisateur est déjà engagé
  /// dans une continuation locale du parcours. Il doit donc synchroniser
  /// explicitement les critères de lancement avant la navigation vers Home.
  Future<void> completeManualSourceLoadingToHome({
    required bool hasIptvCatalogReady,
  }) async {
    final selectedProfileId = _selectedProfilePreferences.selectedProfileId
        ?.trim();
    final selectedSourceId =
        _selectedIptvSourcePreferences.selectedSourceId?.trim();
    final hasSelectedProfile =
        selectedProfileId != null && selectedProfileId.isNotEmpty;
    final hasSelectedSource =
        selectedSourceId != null && selectedSourceId.isNotEmpty;

    AppLaunchCriteria criteria({
      required bool hasHomePreloaded,
      required bool hasLibraryReady,
    }) {
      return AppLaunchCriteria(
        hasSession: state.criteria.hasSession,
        hasSelectedProfile: hasSelectedProfile,
        hasSelectedSource: hasSelectedSource,
        hasIptvCatalogReady: hasIptvCatalogReady,
        hasHomePreloaded: hasHomePreloaded,
        hasLibraryReady: hasLibraryReady,
      );
    }

    _updateState(
      state.copyWith(
        status: AppLaunchStatus.running,
        phase: AppLaunchPhase.preloadCompleteHome,
        completedAt: null,
        error: null,
        destination: null,
        criteria: criteria(
          hasHomePreloaded: false,
          hasLibraryReady: false,
        ),
        recovery: null,
        recoveryMessage: null,
      ),
    );

    await _preloadHomeForLaunch();
    _updateState(
      state.copyWith(
        criteria: criteria(
          hasHomePreloaded: true,
          hasLibraryReady: false,
        ),
      ),
    );

    await _ensureLibraryReadyForLaunch();
    setResolvedDestination(
      BootstrapDestination.home,
      criteria: criteria(hasHomePreloaded: true, hasLibraryReady: true),
    );
  }

  Future<AppLaunchResult> _runInternal() async {
    var step = 'init';
    var destination = BootstrapDestination.auth;
    var meta = const AppLaunchMeta();

    void updateCriteria() {
      _updateState(
        state.copyWith(
          criteria: AppLaunchCriteria.fromLaunchContext(
            accountId: meta.accountId,
            selectedProfileId: meta.selectedProfileId,
            selectedSourceId: meta.selectedSourceId,
            hasIptvCatalogReady: meta.iptvCatalogReady,
            hasHomePreloaded: meta.homePreloaded,
            hasLibraryReady: meta.libraryReady,
          ),
        ),
      );
    }

    void setRecovery(AppLaunchRecovery? recovery) {
      _updateState(state.copyWith(recovery: recovery));
    }

    Future<void> logStep(String message) async {
      final pc = meta.profilesCount?.toString() ?? 'n/a';
      final sc = meta.sourcesCount?.toString() ?? 'n/a';
      final lc = meta.localAccountsCount?.toString() ?? 'n/a';
      final dest = destination.name;
      final hasAccount = meta.accountId != null;
      final hasSelectedProfile = meta.selectedProfileId != null;
      final hasSelectedSource = meta.selectedSourceId != null;

      await LoggingService.log(
        '[Preload] step=$step hasAccount=$hasAccount profiles=$pc '
        'sources=$sc local=$lc hasSelectedProfile=$hasSelectedProfile '
        'hasSelectedSource=$hasSelectedSource dest=$dest :: $message',
      );
    }

    AppLaunchResult completeSuccess(BootstrapDestination nextDestination) {
      destination = nextDestination;
      _updateState(
        state.copyWith(
          status: AppLaunchStatus.success,
          phase: AppLaunchPhase.done,
          completedAt: DateTime.now(),
          error: null,
          destination: destination,
        ),
      );
      _logPhase(
        AppLaunchPhase.done,
        AppLaunchStatus.success,
        stepName: 'done',
        runId: state.runId,
      );
      final reasonCode =
          state.recovery?.reasonCode ??
          _reasonCodeForDestination(nextDestination);
      if (nextDestination != BootstrapDestination.home) {
        _entryJourneyTelemetry.event(
          name: 'entry_journey_safe_state_reached',
          runId: state.runId ?? 'missing',
          result: 'success',
          phase: AppLaunchPhase.done.name,
          step: 'done',
          reasonCode: reasonCode,
          elapsedMs: _elapsedSinceStartMs(),
          fields: <String, Object?>{'destination': nextDestination.name},
        );
      }
      _entryJourneyTelemetry.event(
        name: 'entry_journey_completed',
        runId: state.runId ?? 'missing',
        result: 'success',
        phase: AppLaunchPhase.done.name,
        step: 'done',
        reasonCode: reasonCode,
        elapsedMs: _elapsedSinceStartMs(),
        fields: <String, Object?>{'destination': nextDestination.name},
      );
      return AppLaunchResult(destination: destination, meta: meta);
    }

    AppLaunchResult completeFailure(Object error, StackTrace st) {
      final code = error is _LaunchStepException ? error.code.name : 'unknown';
      final failure = Failure.fromException(
        error,
        stackTrace: st,
        code: 'app_launch',
        context: {'step': step, 'userId': meta.accountId, 'errorCode': code},
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
          'type=${error.runtimeType} code=$code msg=$error',
        ),
      );

      _updateState(
        state.copyWith(
          status: AppLaunchStatus.failure,
          error: launchFailure,
          completedAt: DateTime.now(),
          destination: null,
        ),
      );
      _logPhase(
        AppLaunchPhase.done,
        AppLaunchStatus.failure,
        stepName: 'failed',
        runId: state.runId,
      );
      _entryJourneyTelemetry.event(
        name: 'entry_journey_failed',
        runId: state.runId ?? 'missing',
        result: 'failure',
        phase: AppLaunchPhase.done.name,
        step: step,
        reasonCode: 'launch_failure_$code',
        elapsedMs: _elapsedSinceStartMs(),
        fields: <String, Object?>{'errorCode': code},
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
      _entryJourneyTelemetry.event(
        name: 'entry_journey_stage_completed',
        runId: state.runId ?? 'missing',
        result: 'success',
        phase: AppLaunchPhase.startup.name,
        step: step,
        reasonCode: 'startup_ready',
        elapsedMs: _elapsedSinceStartMs(),
      );

      step = 'auth_session';
      _setPhase(AppLaunchPhase.auth, stepName: step);
      final authResult = await ref
          .read(authOrchestratorProvider)
          .bootstrapSession();
      final session = authResult.snapshot.session;
      const supabaseConfig = SupabaseConfig.fromEnvironment;
      final isCloudAuthEnabled =
          supabaseConfig.isConfigured ||
          ref.read(supabaseClientProvider) != null;
      if (authResult.isAuthenticated && session != null) {
        setRecovery(null);
        meta = meta.copyWith(accountId: session.userId);
        updateCriteria();
        await logStep('session validated');
        _entryJourneyTelemetry.event(
          name: 'session_resolved',
          runId: state.runId ?? 'missing',
          result: 'authenticated',
          phase: AppLaunchPhase.auth.name,
          step: step,
          reasonCode: authResult.reasonCode ?? 'session_authenticated',
          elapsedMs: _elapsedSinceStartMs(),
          fields: <String, Object?>{'hasSession': true},
        );
        _entryJourneyTelemetry.event(
          name: 'entry_journey_stage_completed',
          runId: state.runId ?? 'missing',
          result: 'success',
          phase: AppLaunchPhase.auth.name,
          step: step,
          reasonCode: authResult.reasonCode ?? 'session_authenticated',
          elapsedMs: _elapsedSinceStartMs(),
        );
      } else if (isCloudAuthEnabled && authResult.requiresReauthentication) {
        final recovery = _buildAuthRecovery(authResult);
        setRecovery(recovery);
        await logStep(
          'invalid session -> explicit reauth (${recovery?.reasonCode ?? 'none'})',
        );
        _entryJourneyTelemetry.event(
          name: 'session_resolved',
          runId: state.runId ?? 'missing',
          result: 'reauth_required',
          phase: AppLaunchPhase.auth.name,
          step: step,
          reasonCode: recovery?.reasonCode ?? authResult.reasonCode,
          elapsedMs: _elapsedSinceStartMs(),
          fields: <String, Object?>{'hasSession': false},
        );
        destination = BootstrapDestination.auth;
        return completeSuccess(destination);
      } else if (isCloudAuthEnabled && authResult.isDegradedRetryable) {
        final recovery = _buildAuthRecovery(authResult);
        setRecovery(recovery);
        await logStep(
          'session recovery degraded -> local-first continuation '
          '(${recovery?.reasonCode ?? 'none'})',
        );
        _entryJourneyTelemetry.event(
          name: 'session_resolved',
          runId: state.runId ?? 'missing',
          result: 'degraded_retryable',
          phase: AppLaunchPhase.auth.name,
          step: step,
          reasonCode: recovery?.reasonCode ?? authResult.reasonCode,
          elapsedMs: _elapsedSinceStartMs(),
          fields: <String, Object?>{'hasSession': false},
        );
        _entryJourneyTelemetry.event(
          name: 'entry_journey_stage_completed',
          runId: state.runId ?? 'missing',
          result: 'degraded',
          phase: AppLaunchPhase.auth.name,
          step: step,
          reasonCode: recovery?.reasonCode ?? authResult.reasonCode,
          elapsedMs: _elapsedSinceStartMs(),
        );
      } else if (isCloudAuthEnabled) {
        setRecovery(_buildAuthRecovery(authResult));
        await logStep('session unverifiable -> safe auth path');
        _entryJourneyTelemetry.event(
          name: 'session_resolved',
          runId: state.runId ?? 'missing',
          result: 'blocked',
          phase: AppLaunchPhase.auth.name,
          step: step,
          reasonCode:
              authResult.reasonCode ??
              state.recovery?.reasonCode ??
              'auth_required',
          elapsedMs: _elapsedSinceStartMs(),
          fields: <String, Object?>{'hasSession': false},
        );
        destination = BootstrapDestination.auth;
        return completeSuccess(destination);
      } else {
        setRecovery(null);
        await logStep('no validated session -> local mode');
        _entryJourneyTelemetry.event(
          name: 'session_resolved',
          runId: state.runId ?? 'missing',
          result: 'local_mode',
          phase: AppLaunchPhase.auth.name,
          step: step,
          reasonCode: 'local_mode',
          elapsedMs: _elapsedSinceStartMs(),
          fields: <String, Object?>{'hasSession': false},
        );
        _entryJourneyTelemetry.event(
          name: 'entry_journey_stage_completed',
          runId: state.runId ?? 'missing',
          result: 'degraded',
          phase: AppLaunchPhase.auth.name,
          step: step,
          reasonCode: 'local_mode',
          elapsedMs: _elapsedSinceStartMs(),
        );
      }

      step = 'profiles_fetch';
      _setPhase(AppLaunchPhase.profiles, stepName: step);
      final profiles = await _profileRepository.getProfiles(
        accountId: meta.accountId,
      );
      meta = meta.copyWith(profilesCount: profiles.length);
      await logStep('profiles fetched');
      _entryJourneyTelemetry.event(
        name: 'profiles_inventory_loaded',
        runId: state.runId ?? 'missing',
        result: 'success',
        phase: AppLaunchPhase.profiles.name,
        step: step,
        reasonCode: profiles.isEmpty ? 'profile_missing' : 'profiles_loaded',
        elapsedMs: _elapsedSinceStartMs(),
        fields: <String, Object?>{'profilesCount': profiles.length},
      );
      _entryJourneyTelemetry.event(
        name: 'entry_journey_stage_completed',
        runId: state.runId ?? 'missing',
        result: 'success',
        phase: AppLaunchPhase.profiles.name,
        step: step,
        reasonCode: profiles.isEmpty ? 'profile_missing' : 'profiles_loaded',
        elapsedMs: _elapsedSinceStartMs(),
      );

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

      step = 'local_accounts_fetch';
      _setPhase(AppLaunchPhase.localAccounts, stepName: step);
      var localAccounts = await _iptvLocalRepository.getAccounts();
      var localStalkerAccounts = await _iptvLocalRepository
          .getStalkerAccounts();
      var totalLocalCount = localAccounts.length + localStalkerAccounts.length;
      meta = meta.copyWith(localAccountsCount: totalLocalCount);
      await logStep(
        'local accounts fetched (xtream=${localAccounts.length} '
        'stalker=${localStalkerAccounts.length})',
      );
      _entryJourneyTelemetry.event(
        name: 'sources_inventory_loaded',
        runId: state.runId ?? 'missing',
        result: 'success',
        phase: AppLaunchPhase.localAccounts.name,
        step: step,
        reasonCode: totalLocalCount == 0 ? 'source_missing' : 'sources_loaded',
        elapsedMs: _elapsedSinceStartMs(),
        fields: <String, Object?>{
          'localSourcesCount': totalLocalCount,
          'remoteSourcesCount': meta.sourcesCount ?? 0,
        },
      );

      var supaSources = const <SupabaseIptvSourceEntity>[];
      if (localAccounts.isEmpty && localStalkerAccounts.isEmpty) {
        final remoteAccountId = meta.accountId?.trim();
        final remoteSourcesRepository = _iptvSourcesRepository;

        if (remoteSourcesRepository != null &&
            remoteAccountId != null &&
            remoteAccountId.isNotEmpty) {
          step = 'sources_fetch';
          _setPhase(AppLaunchPhase.sources, stepName: step);
          try {
            supaSources = await remoteSourcesRepository.getSources(
              accountId: remoteAccountId,
            );
            meta = meta.copyWith(sourcesCount: supaSources.length);
            await logStep('sources fetched');
          } catch (e, st) {
            if (kDebugMode) {
              debugPrint(
                '[Bootstrap] Remote sources fetch failed, continuing local-first: $e\n$st',
              );
            }
            await logStep('sources fetch failed -> local-only fallback');
          }

          if (supaSources.isNotEmpty) {
            unawaited(
              _migrateLegacySupabaseCredentialsToEdge(
                accountId: meta.accountId,
                sources: supaSources,
              ),
            );

            step = 'local_accounts_hydrate_from_supabase';
            _setPhase(AppLaunchPhase.localAccounts, stepName: step);
            final hydrated = await _hydrateLocalAccountsFromSupabase(
              accountId: meta.accountId,
              sources: supaSources,
            );
            await logStep('local hydrated=$hydrated');

            final refreshed = await _iptvLocalRepository.getAccounts();
            localAccounts = refreshed;
            localStalkerAccounts = await _iptvLocalRepository
                .getStalkerAccounts();
            totalLocalCount = refreshed.length + localStalkerAccounts.length;
            meta = meta.copyWith(localAccountsCount: totalLocalCount);
            await logStep(
              'local accounts refetched (xtream=${refreshed.length} '
              'stalker=${localStalkerAccounts.length})',
            );
            _entryJourneyTelemetry.event(
              name: 'sources_inventory_loaded',
              runId: state.runId ?? 'missing',
              result: 'success',
              phase: AppLaunchPhase.localAccounts.name,
              step: step,
              reasonCode: totalLocalCount == 0
                  ? 'source_missing'
                  : 'sources_hydrated_from_cloud',
              elapsedMs: _elapsedSinceStartMs(),
              fields: <String, Object?>{
                'localSourcesCount': totalLocalCount,
                'remoteSourcesCount': supaSources.length,
              },
            );
          }
        } else {
          meta = meta.copyWith(sourcesCount: 0);
          await logStep('no remote source repo/session -> local-only fallback');
        }
      }

      if (localAccounts.isEmpty && localStalkerAccounts.isEmpty) {
        destination = BootstrapDestination.welcomeSources;
        await logStep('no local accounts available -> welcomeSources');
        return completeSuccess(destination);
      }

      step = 'iptv_source_selection';
      _setPhase(AppLaunchPhase.sourceSelection, stepName: step);
      final validIds = {
        ...localAccounts.map((a) => a.id),
        ...localStalkerAccounts.map((a) => a.id),
      };

      final accountIdForCloud = meta.accountId?.trim();
      final supabaseClient = ref.read(supabaseClientProvider);

      if (accountIdForCloud != null &&
          accountIdForCloud.isNotEmpty &&
          validIds.length > 1 &&
          supabaseClient != null) {
        try {
          await ref
              .read(comprehensiveCloudSyncServiceProvider)
              .pullUserPreferences(
                client: supabaseClient,
                shouldCancel: () => false,
                knownIptvAccountIds: validIds,
              );
          await logStep('user prefs pulled from cloud (iptv selection)');
        } catch (e, st) {
          if (kDebugMode) {
            debugPrint(
              '[Bootstrap] pullUserPreferences before iptv selection: $e\n$st',
            );
          }
          await logStep('pullUserPreferences failed (ignored)');
        }
      }

      await _selectedIptvSourcePreferences.rereadFromStorage();
      String? preferred = _selectedIptvSourcePreferences.selectedSourceId;

      if (validIds.length > 1 &&
          (preferred == null ||
              preferred.trim().isEmpty ||
              !validIds.contains(preferred.trim())) &&
          supabaseClient != null &&
          accountIdForCloud != null &&
          accountIdForCloud.isNotEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        try {
          await ref
              .read(comprehensiveCloudSyncServiceProvider)
              .pullUserPreferences(
                client: supabaseClient,
                shouldCancel: () => false,
                knownIptvAccountIds: validIds,
              );
          await logStep('user prefs pulled from cloud (iptv selection retry)');
        } catch (e, st) {
          if (kDebugMode) {
            debugPrint(
              '[Bootstrap] pullUserPreferences retry before iptv selection: $e\n$st',
            );
          }
          await logStep('pullUserPreferences retry failed (ignored)');
        }
        await _selectedIptvSourcePreferences.rereadFromStorage();
        preferred = _selectedIptvSourcePreferences.selectedSourceId;
      }

      final preferredFinal = preferred;
      if (kDebugMode) {
        debugPrint(
          '[BOOTSTRAP] Preferred source present=${preferredFinal != null} '
          'validIds=${validIds.length}',
        );
      }

      if (validIds.length == 1) {
        final onlyId = validIds.first;
        meta = meta.copyWith(selectedSourceId: onlyId);
        updateCriteria();
        if (preferredFinal != onlyId) {
          await _selectedIptvSourcePreferences.setSelectedSourceId(onlyId);
          _appStateController.setActiveIptvSources({onlyId});
          await logStep('single source selected -> $onlyId');
        } else {
          _appStateController.setActiveIptvSources({onlyId});
          await logStep('single source already selected -> $onlyId');
        }
        _entryJourneyTelemetry.event(
          name: 'source_selection_resolved',
          runId: state.runId ?? 'missing',
          result: 'auto_selected',
          phase: AppLaunchPhase.sourceSelection.name,
          step: step,
          reasonCode: 'source_single_auto_selected',
          elapsedMs: _elapsedSinceStartMs(),
          fields: <String, Object?>{'sourcesCount': validIds.length},
        );
      } else if (preferredFinal != null &&
          validIds.contains(preferredFinal.trim())) {
        final trimmed = preferredFinal.trim();
        meta = meta.copyWith(selectedSourceId: trimmed);
        updateCriteria();
        _appStateController.setActiveIptvSources({trimmed});
        await logStep('selected source restored -> $trimmed');
        _entryJourneyTelemetry.event(
          name: 'source_selection_resolved',
          runId: state.runId ?? 'missing',
          result: 'restored',
          phase: AppLaunchPhase.sourceSelection.name,
          step: step,
          reasonCode: 'source_selection_restored',
          elapsedMs: _elapsedSinceStartMs(),
          fields: <String, Object?>{'sourcesCount': validIds.length},
        );
      } else {
        final stale = preferredFinal?.trim();
        if (stale != null && stale.isNotEmpty && !validIds.contains(stale)) {
          await _selectedIptvSourcePreferences.clear();
        }
        _entryJourneyTelemetry.event(
          name: 'source_selection_resolved',
          runId: state.runId ?? 'missing',
          result: 'manual_selection_required',
          phase: AppLaunchPhase.sourceSelection.name,
          step: step,
          reasonCode: 'source_selection_required',
          elapsedMs: _elapsedSinceStartMs(),
          fields: <String, Object?>{'sourcesCount': validIds.length},
        );
        destination = BootstrapDestination.chooseSource;
        await logStep('multiple sources + no valid selection -> chooseSource');
        return completeSuccess(destination);
      }
      _entryJourneyTelemetry.event(
        name: 'entry_journey_stage_completed',
        runId: state.runId ?? 'missing',
        result: 'success',
        phase: AppLaunchPhase.sourceSelection.name,
        step: step,
        reasonCode: 'source_selection_resolved',
        elapsedMs: _elapsedSinceStartMs(),
      );

      step = 'preload_complete_home';
      _setPhase(AppLaunchPhase.preloadCompleteHome, stepName: step);
      final iptvPreload = await _ensureIptvCatalogReadyForLaunch();
      meta = meta.copyWith(iptvCatalogReady: iptvPreload.catalogReady);
      updateCriteria();
      await logStep('iptv catalog ready for launch');
      _entryJourneyTelemetry.event(
        name: 'catalog_minimal_ready',
        runId: state.runId ?? 'missing',
        result: iptvPreload.catalogReady ? 'success' : 'failure',
        phase: AppLaunchPhase.preloadCompleteHome.name,
        step: step,
        reasonCode: iptvPreload.catalogReady
            ? 'catalog_minimal_ready'
            : 'catalog_minimal_not_ready',
        elapsedMs: _elapsedSinceStartMs(),
        fields: <String, Object?>{'refreshed': iptvPreload.refreshed},
      );

      await _runWithRetry<void>(
        attempts: 2,
        initialDelay: const Duration(milliseconds: 200),
        actionName: 'home_preload',
        action: (_) => _preloadHomeForLaunch(),
      );
      meta = meta.copyWith(homePreloaded: true);
      updateCriteria();
      await logStep('home preload done');

      await _ensureLibraryReadyForLaunch();
      meta = meta.copyWith(libraryReady: true);
      updateCriteria();
      await logStep('library preload done');
      _entryJourneyTelemetry.event(
        name: 'catalog_full_load_completed',
        runId: state.runId ?? 'missing',
        result: 'success',
        phase: AppLaunchPhase.preloadCompleteHome.name,
        step: step,
        reasonCode: 'catalog_full_load_completed',
        elapsedMs: _elapsedSinceStartMs(),
        fields: <String, Object?>{'homePreloaded': true, 'libraryReady': true},
      );
      _entryJourneyTelemetry.event(
        name: 'entry_journey_stage_completed',
        runId: state.runId ?? 'missing',
        result: 'success',
        phase: AppLaunchPhase.preloadCompleteHome.name,
        step: step,
        reasonCode: 'preload_complete',
        elapsedMs: _elapsedSinceStartMs(),
      );

      destination = BootstrapDestination.home;
      await logStep('complete preload done -> home');
      final result = completeSuccess(destination);

      _startIptvBackgroundSync(meta);
      return result;
    } catch (e, st) {
      return completeFailure(e, st);
    }
  }

  Future<_IptvPreloadResult> _ensureIptvCatalogReadyForLaunch() async {
    return _runWithRetry<_IptvPreloadResult>(
      attempts: 3,
      initialDelay: const Duration(milliseconds: 300),
      actionName: 'iptv_preload',
      action: (attempt) async {
        final result =
            await _ensureIptvCatalogReady(
              reason: 'launch_attempt_$attempt',
            ).timeout(
              const Duration(seconds: 20),
              onTimeout: () {
                throw const _LaunchStepException(
                  AppLaunchErrorCode.iptvNetworkTimeout,
                  'IPTV catalog preload timed out',
                );
              },
            );
        if (!result.catalogReady) {
          throw const _LaunchStepException(
            AppLaunchErrorCode.iptvEmptyData,
            'IPTV catalog is empty after refresh',
          );
        }
        return result;
      },
    );
  }

  Future<void> _preloadHomeForLaunch() async {
    if (!_homeController.bootstrapPreloadInFlight) {
      await _homePreload(
        awaitIptv: true,
        reason: 'preload',
        force: true,
        cooldown: Duration.zero,
      );
    }
    await _homeController.waitForBootstrapPreloadCompletion().timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        throw const _LaunchStepException(
          AppLaunchErrorCode.homePreloadInvalidState,
          'Timed out while waiting for bootstrap preload completion',
        );
      },
    );

    var homeState = ref.read(homeControllerProvider);
    if (homeState.isLoading && _homeController.bootstrapPreloadInFlight) {
      await _homeController.waitForBootstrapPreloadCompletion().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw const _LaunchStepException(
            AppLaunchErrorCode.homePreloadInvalidState,
            'Home preload remained inflight beyond timeout',
          );
        },
      );
      homeState = ref.read(homeControllerProvider);
    }
    if (homeState.isLoading) {
      throw const _LaunchStepException(
        AppLaunchErrorCode.homePreloadInvalidState,
        'Home preload still loading after awaited preload',
      );
    }
    if (homeState.error != null && homeState.error!.trim().isNotEmpty) {
      throw _LaunchStepException(
        AppLaunchErrorCode.homePreloadInvalidState,
        'Home preload failed: ${homeState.error}',
      );
    }
    final hasActiveSources = _appStateController.activeIptvSourceIds.isNotEmpty;
    if (hasActiveSources && homeState.iptvLists.isEmpty) {
      throw const _LaunchStepException(
        AppLaunchErrorCode.homePreloadInvalidState,
        'Home preload finished without IPTV sections',
      );
    }
  }

  Future<void> _ensureLibraryReadyForLaunch() async {
    try {
      await ref
          .read(homeInProgressProvider.future)
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const _LaunchStepException(
        AppLaunchErrorCode.libraryPreloadTimeout,
        'Library preload timed out',
      );
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('not registered') || msg.contains('bad state')) {
        await LoggingService.log(
          '[Preload][WARN] library preload skipped: dependency unavailable',
        );
        return;
      }
      throw _LaunchStepException(
        AppLaunchErrorCode.libraryPreloadTimeout,
        'Library preload failed: $e',
      );
    }
  }

  Future<T> _runWithRetry<T>({
    required int attempts,
    required Duration initialDelay,
    required String actionName,
    required Future<T> Function(int attempt) action,
  }) async {
    Object? lastError;
    for (var attempt = 1; attempt <= attempts; attempt++) {
      try {
        _setRecoveryMessage(
          attempt == 1 ? null : 'Recovery: $actionName ($attempt/$attempts)',
        );
        final result = await action(attempt);
        _setRecoveryMessage(null);
        return result;
      } catch (e) {
        lastError = e;
        if (attempt >= attempts) break;
        final delayMs = initialDelay.inMilliseconds * attempt * attempt;
        _entryJourneyTelemetry.event(
          name: 'entry_journey_retry_scheduled',
          runId: state.runId ?? 'missing',
          result: 'retry',
          phase: state.phase.name,
          step: actionName,
          reasonCode: 'retry_scheduled',
          elapsedMs: _elapsedSinceStartMs(),
          fields: <String, Object?>{
            'attempt': attempt + 1,
            'maxAttempts': attempts,
            'delayMs': delayMs,
          },
        );
        await Future<void>.delayed(Duration(milliseconds: delayMs));
      }
    }
    _setRecoveryMessage(null);
    if (lastError is _LaunchStepException) {
      throw lastError;
    }
    throw _LaunchStepException(
      AppLaunchErrorCode.iptvProviderError,
      'Retry policy exhausted for $actionName: $lastError',
    );
  }

  void _setPhase(AppLaunchPhase phase, {String? stepName}) {
    _assertValidTransition(from: state.phase, to: phase);
    _updateState(state.copyWith(phase: phase));
    _logPhase(phase, state.status, stepName: stepName, runId: state.runId);
    final runId = state.runId;
    if (runId != null && runId.isNotEmpty) {
      _entryJourneyTelemetry.event(
        name: 'entry_journey_stage_entered',
        runId: runId,
        result: state.status.name,
        phase: phase.name,
        step: stepName ?? phase.name,
        reasonCode: 'stage_entered',
        elapsedMs: _elapsedSinceStartMs(),
      );
    }
  }

  void _logPhase(
    AppLaunchPhase phase,
    AppLaunchStatus status, {
    String? stepName,
    String? runId,
  }) {
    final ts = DateTime.now().toIso8601String();
    final step = stepName ?? phase.name;
    final runIdPart = runId == null ? '' : ' runId=$runId';
    unawaited(
      LoggingService.log(
        '[Launch] ts=$ts phase=${phase.name} status=${status.name} step=$step$runIdPart',
      ),
    );
  }

  void _assertValidTransition({
    required AppLaunchPhase from,
    required AppLaunchPhase to,
  }) {
    if (from == to) return;
    final allowed = _allowedPhaseTransitions[from];
    final valid = allowed != null && allowed.contains(to);
    if (valid) return;
    throw _LaunchStepException(
      AppLaunchErrorCode.invalidTransition,
      'Invalid transition from ${from.name} to ${to.name}',
    );
  }

  AppLaunchRecovery? _buildAuthRecovery(AuthBootstrapResult authResult) {
    final cause = authResult.cause;
    final reasonCode = authResult.reasonCode;
    final message = authResult.recoveryMessage;
    if (cause == null || reasonCode == null || message == null) {
      return null;
    }

    final kind = authResult.isDegradedRetryable
        ? AppLaunchRecoveryKind.degradedRetryable
        : AppLaunchRecoveryKind.reauthRequired;

    return AppLaunchRecovery(
      kind: kind,
      cause: cause,
      reasonCode: reasonCode,
      message: message,
    );
  }

  void _setRecoveryMessage(String? message) {
    _updateState(state.copyWith(recoveryMessage: message));
  }

  int? _elapsedSinceStartMs() {
    final startedAt = state.startedAt;
    if (startedAt == null) return null;
    return DateTime.now().difference(startedAt).inMilliseconds;
  }

  String _reasonCodeForDestination(BootstrapDestination destination) {
    switch (destination) {
      case BootstrapDestination.auth:
        return 'auth_required';
      case BootstrapDestination.welcomeUser:
        return 'profile_required';
      case BootstrapDestination.welcomeSources:
        return 'source_required';
      case BootstrapDestination.chooseSource:
        return 'source_selection_required';
      case BootstrapDestination.home:
        return 'home_ready';
    }
  }

  void _logIptvSyncDecision({
    required String reason,
    required String action,
    String? detail,
  }) {
    final ts = DateTime.now().toIso8601String();
    final extra = detail == null ? '' : ' detail=$detail';
    final runId = state.runId == null ? '' : ' runId=${state.runId}';
    unawaited(
      LoggingService.log(
        '[IptvSync] ts=$ts reason=$reason action=$action$extra$runId',
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
      final playlists = await _iptvLocalRepository.getPlaylists(
        id,
        itemLimit: 0,
      );
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
        return const _IptvPreloadResult(catalogReady: true, refreshed: false);
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

    _logIptvSyncDecision(reason: reason, action: 'run', detail: 'refresh_done');
    _appEventBus.emit(const AppEvent(AppEventType.iptvSynced));
    return _IptvPreloadResult(catalogReady: true, refreshed: refreshed);
  }

  Future<void> _runIptvBackgroundSync(AppLaunchMeta meta) async {
    const step = 'iptv_sync_background';
    await LoggingService.log(
      '[Preload] step=$step uid=${meta.accountId ?? 'null'} :: start',
    );

    final result = await _ensureIptvCatalogReady(reason: 'background')
        .timeout(
          const Duration(seconds: 18),
          onTimeout: () {
            debugPrint('[Preload] IPTV sync timeout after 18s (background)');
            return const _IptvPreloadResult(
              catalogReady: false,
              refreshed: false,
            );
          },
        )
        .catchError((e) {
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

        final localId = (s.localId?.trim().isNotEmpty ?? false)
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
    final sourceRepository = _iptvSourcesRepository;
    if (sourceRepository == null) return;

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

        await sourceRepository.updateSource(
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
