import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/core/config/config.dart';
import 'package:movi/src/core/config/config_module.dart' as config_module;
import 'package:movi/src/core/di/di.dart' as di;
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/logging/logging_module.dart';
import 'package:movi/src/core/logging/operation_context.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/core/preferences/iptv_sync_preferences.dart';
import 'package:movi/src/core/startup/domain/startup_contracts.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/features/iptv/application/services/xtream_sync_service.dart';

final class DebugPrintTelemetryAdapter implements StartupTelemetryPort {
  String _prefix() {
    final op = currentOperationId();
    return op == null ? '[Startup]' : '[Startup][op=$op]';
  }

  @override
  void info(String message) => debugPrint('${_prefix()} $message');

  @override
  void warn(String message) => debugPrint('${_prefix()}[WARN] $message');

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    debugPrint('${_prefix()}[ERROR] $message');
    if (error != null) debugPrint('${_prefix()}[ERROR] error=$error');
    if (stackTrace != null) debugPrint(stackTrace.toString());
  }
}

final class FlavorAdapter implements FlavorPort {
  @override
  Object loadFlavor() {
    final loader = EnvironmentLoader();
    config_module.registerEnvironmentLoader(loader);
    return loader.load();
  }
}

final class ConfigAdapter implements ConfigPort {
  @override
  Future<Object> registerConfig({
    required Object flavor,
    required bool requireTmdbKey,
  }) async {
    final typed = flavor as EnvironmentFlavor;
    final config = await config_module.registerConfig(
      flavor: typed,
      requireTmdbKey: requireTmdbKey,
    );
    return config;
  }
}

final class DependenciesAdapter implements DependenciesPort {
  @override
  Future<void> initDependencies({
    required Object appConfig,
    required String Function() localeProvider,
  }) async {
    await di.initDependencies(
      appConfig: appConfig as AppConfig,
      localeProvider: localeProvider,
    );
  }
}

final class RiverpodAppStateControllerAdapter implements AppStateControllerPort {
  RiverpodAppStateControllerAdapter(this._ref);

  final Ref _ref;

  @override
  Object get controller => _ref.read(appStateProvider.notifier);
}

final class GetItAppStateExposureAdapter implements AppStateExposurePort {
  @override
  void exposeAppStateController(Object controller) {
    di.replace<AppStateController>(controller as AppStateController);
  }
}

final class GetItLoggingAdapter implements LoggingPort {
  GetItLoggingAdapter(this._telemetry);

  final StartupTelemetryPort _telemetry;

  @override
  void register() {
    // Idempotent: safe to call even if already registered.
    LoggingModule.register();
  }

  @override
  void logStartupProgress(String message) {
    if (!di.sl.isRegistered<AppLogger>()) return;
    di.sl<AppLogger>().info(
      'feature=startup action=bootstrap result=progress message="$message"',
      category: 'startup',
    );
  }

  @override
  void logStartupSuccess({required int durationMs}) {
    if (!di.sl.isRegistered<AppLogger>()) return;
    di.sl<AppLogger>().info(
      'feature=startup action=bootstrap result=success durationMs=$durationMs',
      category: 'startup',
    );
  }

  @override
  void logStartupFailure({
    required StartupFailureCode code,
    required StartupPhase phase,
    required String message,
  }) {
    // Prefer AppLogger if ready, otherwise fallback to telemetry.
    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().warn(
        'feature=startup action=bootstrap result=failure '
        'code=${code.name} phase=${phase.name} message="$message"',
        category: 'startup',
      );
      return;
    }
    _telemetry.warn(
      'feature=startup action=bootstrap result=failure '
      'code=${code.name} phase=${phase.name} message="$message"',
    );
  }

  /// Optional extra signal used by the legacy flow (kept as best-effort).
  void supabaseSanityCheck() {
    try {
      const cfg = SupabaseConfig.fromEnvironment;
      if (cfg.isConfigured && di.sl.isRegistered<SupabaseClient>()) {
        final client = Supabase.instance.client;
        final url = client.rest.url.toString();
        final safeUrl = url.length > 32 ? '${url.substring(0, 32)}...' : url;
        // Avoid logging user identifiers early-boot. Keep it correlation-friendly.
        final isAuthed = client.auth.currentUser != null;
        _telemetry.info(
          'feature=startup action=supabase_sanity result=ready '
          'url=$safeUrl isAuthed=$isAuthed',
        );
      } else {
        _telemetry.info(
          'feature=startup action=supabase_sanity result=skipped '
          'reason=not_configured_or_not_registered',
        );
      }
    } catch (e, st) {
      _telemetry.warn(
        'feature=startup action=supabase_sanity result=not_ready type=${e.runtimeType}',
      );
      _telemetry.error(
        'feature=startup action=supabase_sanity result=not_ready_stack',
        error: e,
        stackTrace: st,
      );
    }
  }
}

final class IptvSyncAdapter implements IptvSyncPort {
  IptvSyncAdapter();
  StreamSubscription<Duration>? _sub;

  @override
  void setupIntervalFromPreferences() {
    final syncService = di.sl<XtreamSyncService>();
    final iptvSyncPrefs = di.sl<IptvSyncPreferences>();
    syncService.setInterval(iptvSyncPrefs.syncInterval);
  }

  @override
  void bindIntervalUpdates() {
    final syncService = di.sl<XtreamSyncService>();
    final iptvSyncPrefs = di.sl<IptvSyncPreferences>();
    _sub?.cancel();
    _sub = iptvSyncPrefs.syncIntervalStream.listen((interval) {
      syncService.setInterval(interval);
    });
  }

  @override
  void stopOnDispose(void Function(void Function()) onDispose) {
    final syncService = di.sl<XtreamSyncService>();
    onDispose(() {
      _sub?.cancel();
      _sub = null;
      syncService.stop();
    });
  }
}

String defaultLocaleProviderFromGetIt() {
  if (!di.sl.isRegistered<LocalePreferences>()) return 'en-US';
  return di.sl<LocalePreferences>().languageCode;
}

