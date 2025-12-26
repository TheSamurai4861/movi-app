import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:movi/src/core/startup/app_startup_provider.dart' as app_startup_provider;
import 'package:movi/src/core/theme/app_theme.dart';
import 'package:movi/src/core/widgets/widgets.dart';
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
      return _buildStartupMaterialApp(
        const _StartupLoadingScreen(),
      );
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
    debugPrint('[Startup] success, navigate to Home');
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
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    themeMode: ThemeMode.dark,
    theme: AppTheme.dark(),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: _startupLocalizationsDelegates,
    home: home,
  );
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
    return Scaffold(
      body: OverlaySplash(message: l10n.overlayPreparingHome),
    );
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
