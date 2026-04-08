import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:movi/src/core/app_update/presentation/providers/app_update_provider.dart';
import 'package:movi/src/core/app_update/presentation/widgets/app_update_blocked_screen.dart';
import 'package:movi/src/core/preferences/accent_color_preferences.dart';
import 'package:movi/src/core/startup/app_startup_provider.dart'
    as app_startup_provider;
import 'package:movi/src/core/startup/domain/startup_contracts.dart';
import 'package:movi/src/core/theme/app_theme.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/core/widgets/movi_remote_navigation.dart';
import 'package:movi/src/core/widgets/movi_scroll_behavior.dart';
import 'package:movi/l10n/app_localizations.dart';

/// Shared localization delegates used by the startup MaterialApp.
///
/// Keeping this in a single constant avoids duplication and ensures
/// consistency with the main app configuration.
const List<LocalizationsDelegate<dynamic>> _startupLocalizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// Gate widget responsible for running the app’s initialization logic
/// before rendering the main application.
///
/// Behaviour:
/// - While bootstrapping → displays a minimal dark loading screen.
/// - On startup failure → displays an error screen with translated retry button.
/// - On success → renders the provided [child] (typically `MyApp`).
class AppStartupGate extends ConsumerWidget {
  const AppStartupGate({super.key, required this.child});

  /// The widget tree to render once the startup process is successful.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watches the global startup state (loading / error / success).
    final state = ref.watch(app_startup_provider.appStartupProvider);

    // Compile-time flag that forces showing detailed technical errors,
    // useful for IPA / TestFlight debugging or internal dev builds.
    const bool forceStartupDetails = bool.fromEnvironment(
      'FORCE_STARTUP_DETAILS',
      defaultValue: false,
    );

    // --- Loading state -----------------------------------------------------
    if (state.isLoading) {
      debugPrint('[Startup] loading...');
      return _buildStartupMaterialApp(const _StartupLoadingScreen());
    }

    // --- Error state -------------------------------------------------------
    if (state.hasError) {
      final rawDetails = state.error?.toString() ?? 'Unknown startup error';

      // Only show verbose details in dev builds or if forced at compile-time.
      final showDetails = !kReleaseMode || forceStartupDetails;

      debugPrint('[Startup] error: $rawDetails');

      return _buildStartupMaterialApp(
        _StartupErrorScreen(
          displayDetails: rawDetails,
          showDetails: showDetails,
          // `invalidate` relance le provider sans utiliser la valeur retournée.
          onRetry: () {
            ref.invalidate(app_startup_provider.appStartupProvider);
          },
        ),
      );
    }

    // --- Success state ------------------------------------------------------
    final result = state.asData?.value;
    if (result != null && result.kind == StartupOutcomeKind.safeMode) {
      debugPrint('[Startup] safeMode, keep app alive with reduced UX');
      // SafeMode must stay actionable in production with minimal diagnostics.
      final showDetails = !kReleaseMode || forceStartupDetails;
      return _buildStartupMaterialApp(
        _StartupSafeModeScreen(
          failure: result.failure,
          showDetails: showDetails,
          onRetry: () {
            ref.invalidate(app_startup_provider.appStartupProvider);
          },
        ),
      );
    }

    final appUpdateState = ref.watch(appUpdateDecisionProvider);

    if (appUpdateState.isLoading) {
      debugPrint('[AppUpdate] loading...');
      return _buildStartupMaterialApp(const _StartupLoadingScreen());
    }

    if (appUpdateState.hasError) {
      final rawDetails = appUpdateState.error?.toString() ?? 'Unknown app update error';
      final showDetails = !kReleaseMode || forceStartupDetails;
      debugPrint('[AppUpdate] error: $rawDetails');
      return _buildStartupMaterialApp(
        _StartupErrorScreen(
          displayDetails: rawDetails,
          showDetails: showDetails,
          onRetry: () {
            ref.invalidate(appUpdateDecisionProvider);
          },
        ),
      );
    }

    final appUpdateDecision = appUpdateState.asData?.value;
    if (appUpdateDecision != null && appUpdateDecision.isBlocking) {
      debugPrint(
        '[AppUpdate] blocked status=${appUpdateDecision.status.name} '
        'reasonCode=${appUpdateDecision.reasonCode ?? 'n/a'}',
      );
      return _buildStartupMaterialApp(
        AppUpdateBlockedScreen(
          decision: appUpdateDecision,
          onRetry: () {
            ref.invalidate(appUpdateDecisionProvider);
          },
        ),
      );
    }

    debugPrint('[Startup] ready, navigate to Home');
    return child;
  }
}

/// Builds a minimal MaterialApp used only during the startup phase.
///
/// This ensures:
/// - consistent localization configuration,
/// - no duplication of delegates / supportedLocales,
/// - a clear separation between startup shell and main app.
Widget _buildStartupMaterialApp(Widget home) {
  return _StartupMaterialAppShell(home: home);
}

class _StartupMaterialAppShell extends StatefulWidget {
  const _StartupMaterialAppShell({required this.home});

  final Widget home;

  @override
  State<_StartupMaterialAppShell> createState() =>
      _StartupMaterialAppShellState();
}

class _StartupMaterialAppShellState extends State<_StartupMaterialAppShell> {
  late final Future<Color> _accentColorFuture = _loadAccentColor();

  Future<Color> _loadAccentColor() async {
    try {
      return await AccentColorPreferences.readPersistedAccentColor();
    } catch (_) {
      return AppTheme.dark().colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Color>(
      future: _accentColorFuture,
      builder: (context, snapshot) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          scrollBehavior: const MoviScrollBehavior(),
          themeMode: ThemeMode.dark,
          theme: AppTheme.dark(accentColor: snapshot.data),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: _startupLocalizationsDelegates,
          builder: (context, child) {
            return MoviRemoteNavigation(
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: widget.home,
        );
      },
    );
  }
}

/// Minimal dark loading screen used while the app is initializing.
///
/// No spinner is shown intentionally: Movi's bootstrap is usually fast
/// and this avoids visual flicker before navigation completes.
class _StartupLoadingScreen extends StatelessWidget {
  const _StartupLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(body: OverlaySplash(message: l10n.overlayPreparingHome));
  }
}

/// Screen displayed when startup fails.
///
/// Shows:
/// - A translated error title (`errorPrepareHome`)
/// - Optional technical details (only in dev or if FORCE_STARTUP_DETAILS=true)
/// - A translated retry button (`actionRetry`)
class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({
    required this.displayDetails,
    required this.showDetails,
    required this.onRetry,
  });

  /// Truncated error details.
  final String displayDetails;

  /// Whether to show technical details (dev/test builds only).
  final bool showDetails;

  /// Callback used when the user wants to retry the startup process.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: LaunchErrorPanel(
        message: l10n.errorPrepareHome,
        retryLabel: l10n.actionRetry,
        onRetry: onRetry,
        details: displayDetails,
        showDetails: showDetails,
      ),
    );
  }
}

/// Screen displayed when startup completes in SafeMode (fail-safe degraded path).
///
/// This must stay minimal and actionable.
class _StartupSafeModeScreen extends StatelessWidget {
  const _StartupSafeModeScreen({
    required this.failure,
    required this.onRetry,
    required this.showDetails,
  });

  final StartupFailure? failure;
  final VoidCallback onRetry;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final safeReason = failure?.reasonCode ?? 'startup_safe_mode';

    final details = showDetails
        ? (failure == null
              ? 'SafeMode: reasonCode=$safeReason'
              : 'SafeMode: reasonCode=${failure!.reasonCode} '
                    'code=${failure!.code.name} phase=${failure!.phase.name}\n'
                    '${failure!.message}')
        : 'SafeMode: reasonCode=$safeReason';

    return Scaffold(
      body: LaunchErrorPanel(
        message: l10n.errorPrepareHome,
        retryLabel: l10n.actionRetry,
        onRetry: onRetry,
        details: details,
        showDetails: showDetails,
      ),
    );
  }
}
