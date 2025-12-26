import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/config/config_module.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/core/config/config.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logging_module.dart';
import 'package:movi/src/core/preferences/preferences.dart';
// ignore: unnecessary_import
import 'package:movi/src/core/preferences/iptv_sync_preferences.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/features/iptv/application/services/xtream_sync_service.dart';

final appStartupProvider = FutureProvider<void>((ref) async {
  final sw = Stopwatch()..start();
  debugPrint('[DEBUG][Startup] appStartupProvider: START');
  
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[DEBUG][Startup] appStartupProvider: WidgetsFlutterBinding.ensureInitialized DONE (${sw.elapsedMilliseconds}ms)');

  final loader = EnvironmentLoader();
  registerEnvironmentLoader(loader);
  debugPrint('[DEBUG][Startup] appStartupProvider: EnvironmentLoader registered (${sw.elapsedMilliseconds}ms)');

  final flavor = loader.load();
  final requireTmdbKey = kReleaseMode && flavor.isProduction;

  debugPrint(
    '[Startup] flavor=${flavor.label} (env: ${flavor.environment}) '
    '| requireTmdbKey=$requireTmdbKey',
  );
  debugPrint('[DEBUG][Startup] appStartupProvider: flavor loaded (${sw.elapsedMilliseconds}ms)');

  debugPrint('[DEBUG][Startup] appStartupProvider: registerConfig');
  final config = await registerConfig(
    flavor: flavor,
    requireTmdbKey: requireTmdbKey,
  );
  debugPrint('[DEBUG][Startup] appStartupProvider: registerConfig DONE (${sw.elapsedMilliseconds}ms)');

  // --- DI / modules ----------------------------------------------------------
  debugPrint('[DEBUG][Startup] appStartupProvider: initDependencies');
  await initDependencies(
    appConfig: config,
    localeProvider: () => sl<LocalePreferences>().languageCode,
  );
  debugPrint('[DEBUG][Startup] appStartupProvider: initDependencies DONE (${sw.elapsedMilliseconds}ms)');

  // IMPORTANT:
  // `AppStateController` est un `Notifier<AppState>` Riverpod.
  // Il ne doit jamais être instancié via GetIt, sinon `state/ref` restent
  // non-initialisés → "Tried to use a notifier in an uninitialized state".
  //
  // On expose donc l'instance Riverpod (initialisée par `appStateProvider`)
  // dans GetIt pour les services legacy qui dépendent encore de `sl<AppStateController>()`.
  replace<AppStateController>(ref.read(appStateProvider.notifier));

  // --- Supabase sanity check -------------------------------------------------
  // But: éviter le cas "auth OK mais SupabaseClient pas prêt / mauvais projet".
  // Ici on se contente de loguer un marqueur d'environnement (URL tronquée)
  // et l'état auth courant si dispo.
  try {
    const config = SupabaseConfig.fromEnvironment;
    if (config.isConfigured && sl.isRegistered<SupabaseClient>()) {
      final client = Supabase.instance.client;
      final url = client.rest.url.toString();
      final safeUrl = url.length > 32 ? '${url.substring(0, 32)}...' : url;
      final uid = client.auth.currentUser?.id;
      debugPrint('[Startup] Supabase ready | url=$safeUrl | uid=${uid ?? "null"}');
    } else {
      debugPrint('[Startup] Supabase not configured or client not registered');
    }
  } catch (e, st) {
    debugPrint('[Startup] Supabase not ready: $e\n$st');
  }

  // --- Logging ---------------------------------------------------------------
  LoggingModule.register();

  // --- IPTV background sync --------------------------------------------------
  debugPrint('[DEBUG][Startup] appStartupProvider: XtreamSyncService setup');
  final syncService = sl<XtreamSyncService>();
  final iptvSyncPrefs = sl<IptvSyncPreferences>();

  // S'assurer que l'intervalle est appliqué depuis les préférences
  syncService.setInterval(iptvSyncPrefs.syncInterval);
  debugPrint('[DEBUG][Startup] appStartupProvider: syncService interval set (${sw.elapsedMilliseconds}ms)');

  // Écouter le stream pour mettre à jour dynamiquement si les préférences changent.
  final sub = iptvSyncPrefs.syncIntervalStream.listen((interval) {
    debugPrint('[DEBUG][Startup] appStartupProvider: syncInterval changed to ${interval.inMinutes}m');
    syncService.setInterval(interval);
  });

  // Assurer un cycle de vie propre : à la destruction du provider de startup,
  // on arrête le service de sync et on annule l'abonnement aux préférences.
  ref.onDispose(() {
    debugPrint('[DEBUG][Startup] appStartupProvider: onDispose - stopping sync service');
    sub.cancel();
    syncService.stop();
  });

  sw.stop();
  debugPrint('[DEBUG][Startup] appStartupProvider: COMPLETE (total: ${sw.elapsedMilliseconds}ms)');
});
