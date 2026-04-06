// lib/src/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/auth/domain/repositories/auth_repository.dart';
import 'package:movi/src/core/config/providers/config_provider.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/router/app_route_paths.dart';
import 'package:movi/src/core/router/app_routes.dart';
import 'package:movi/src/core/router/launch_redirect_guard.dart';
import 'package:movi/src/core/router/not_found_page.dart';
import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/core/startup/domain/tunnel_state.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/core/state/app_state_provider.dart';

typedef RouterBundle = ({GoRouter router, LaunchRedirectGuard guard});

class RouterHandle {
  const RouterHandle({required this.router, required this.guard});

  final GoRouter router;
  final LaunchRedirectGuard guard;

  void dispose() {
    router.dispose();
    guard.dispose();
  }
}

RouterBundle createRouterBundle({
  required AppStateController appStateController,
  required AppLogger logger,
  required AuthRepository authRepository,
  required AppLaunchStateRegistry launchRegistry,
  required TunnelStateRegistry tunnelStateRegistry,
  required bool enableEntryJourneyStateModelV2,
  required bool enableEntryJourneyRoutingV2,
}) {
  final guard = LaunchRedirectGuard(
    logger: logger,
    appStateController: appStateController,
    authRepository: authRepository,
    launchRegistry: launchRegistry,
    tunnelStateRegistry: tunnelStateRegistry,
    enableEntryJourneyStateModelV2: enableEntryJourneyStateModelV2,
    enableEntryJourneyRoutingV2: enableEntryJourneyRoutingV2,
  );

  final router = GoRouter(
    initialLocation: const String.fromEnvironment(
      'MOVI_INITIAL_ROUTE',
      defaultValue: AppRoutePaths.launch,
    ),
    refreshListenable: guard,
    redirect: guard.handle,
    routes: buildAppRoutes(guard),
    errorPageBuilder: (context, state) {
      final l10n = AppLocalizations.of(context)!;
      return MaterialPage(
        child: NotFoundPage(
          message: l10n.notFoundWithEntityAndError(
            l10n.entityRoute,
            state.error.toString(),
          ),
        ),
      );
    },
  );

  return (router: router, guard: guard);
}

/// Factory permettant de créer un [GoRouter] en dehors de Riverpod.
///
/// ⚠️ Attention : cette méthode ne permet pas de disposer le [LaunchRedirectGuard]
/// (subscriptions auth + listeners). Préfère [createRouterHandle] (ou
/// [createRouterBundle]) et dispose explicitement `router` + `guard`.
@Deprecated(
  'Use createRouterHandle(...) and dispose it, or createRouterBundle(...).',
)
GoRouter createRouter({
  required AppStateController appStateController,
  required AppLogger logger,
  required AuthRepository authRepository,
}) {
  return createRouterBundle(
    appStateController: appStateController,
    logger: logger,
    authRepository: authRepository,
    launchRegistry: sl<AppLaunchStateRegistry>(),
    tunnelStateRegistry: sl<TunnelStateRegistry>(),
    enableEntryJourneyStateModelV2: false,
    enableEntryJourneyRoutingV2: false,
  ).router;
}

RouterHandle createRouterHandle({
  required AppStateController appStateController,
  required AppLogger logger,
  required AuthRepository authRepository,
}) {
  final bundle = createRouterBundle(
    appStateController: appStateController,
    logger: logger,
    authRepository: authRepository,
    launchRegistry: sl<AppLaunchStateRegistry>(),
    tunnelStateRegistry: sl<TunnelStateRegistry>(),
    enableEntryJourneyStateModelV2: false,
    enableEntryJourneyRoutingV2: false,
  );
  return RouterHandle(router: bundle.router, guard: bundle.guard);
}

/// Provider global du routeur.
///
/// Gère également le cycle de vie du [GoRouter] et du [LaunchRedirectGuard].
final appRouterProvider = Provider<GoRouter>((ref) {
  final appStateController = ref.watch(appStateControllerProvider);
  final sl = ref.watch(slProvider);
  final featureFlags = ref.watch(featureFlagsProvider);

  final logger = sl<AppLogger>();
  final authRepository = sl<AuthRepository>();
  final launchRegistry = sl<AppLaunchStateRegistry>();
  final tunnelStateRegistry = sl<TunnelStateRegistry>();

  final bundle = createRouterBundle(
    appStateController: appStateController,
    logger: logger,
    authRepository: authRepository,
    launchRegistry: launchRegistry,
    tunnelStateRegistry: tunnelStateRegistry,
    enableEntryJourneyStateModelV2: featureFlags.enableEntryJourneyStateModelV2,
    enableEntryJourneyRoutingV2: featureFlags.enableEntryJourneyRoutingV2,
  );

  ref.onDispose(() {
    bundle.router.dispose();
    bundle.guard.dispose();
  });

  return bundle.router;
});
