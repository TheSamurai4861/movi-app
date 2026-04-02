import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/logging/operation_context.dart';
import 'package:movi/src/core/startup/domain/app_startup_orchestrator.dart';
import 'package:movi/src/core/startup/domain/startup_contracts.dart';
import 'package:movi/src/core/startup/infrastructure/startup_adapters.dart';

final appStartupProvider = FutureProvider<StartupResult>((ref) async {
  return runWithOperationId(() async {
    WidgetsFlutterBinding.ensureInitialized();

    final telemetry = DebugPrintTelemetryAdapter();
    final logging = GetItLoggingAdapter(telemetry);

    // Matches legacy behavior: only require TMDB key in production release.
    final requireTmdbKey = kReleaseMode;

    final orchestrator = AppStartupOrchestrator(
      telemetry: telemetry,
      flavorPort: FlavorAdapter(),
      configPort: ConfigAdapter(),
      dependenciesPort: DependenciesAdapter(),
      appStateControllerPort: RiverpodAppStateControllerAdapter(ref),
      appStateExposurePort: GetItAppStateExposureAdapter(),
      loggingPort: logging,
      iptvSyncPort: IptvSyncAdapter(),
      requireTmdbKey: requireTmdbKey,
    );

    final result = await orchestrator.run(
      localeProvider: defaultLocaleProviderFromGetIt,
      onDispose: ref.onDispose,
    );
    // Runs after the orchestrator so logs can be correlated and (if available)
    // captured by the configured logging pipeline.
    logging.supabaseSanityCheck();
    return result;
  }, prefix: 'startup');
});
