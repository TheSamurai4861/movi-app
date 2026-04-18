import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'package:movi/src/core/router/auth_recovery_deep_link_bridge.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as app_state;
import 'package:movi/src/core/subscription/subscription.dart';
import 'package:movi/src/core/theme/theme.dart';
import 'package:movi/src/features/library/presentation/widgets/library_cloud_sync_bootstrapper.dart';
import 'package:movi/src/core/widgets/movi_remote_navigation.dart';
import 'package:movi/src/core/widgets/movi_scroll_behavior.dart';
import 'package:movi/src/features/series_tracking/presentation/widgets/series_tracking_bootstrapper.dart';
import 'package:movi/l10n/app_localizations.dart';

/// Shared localization delegates used by the main [MaterialApp].
///
/// Defined once here to avoid duplication and keep the configuration
/// aligned with the startup shell and other potential entry points.
const List<LocalizationsDelegate<dynamic>> _appLocalizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// Root widget of the Movi application.
///
/// This widget wires:
/// - the global router ([appRouterProvider]),
/// - theming (light/dark + dynamic accent color),
/// - locale / localization,
/// and exposes them through a [MaterialApp.router].
///
/// Because it is a [ConsumerStatefulWidget], it rebuilds automatically whenever
/// one of the watched providers (router, theme, locale, accent) changes.
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key, this.launchArgs = const <String>[]});

  final List<String> launchArgs;

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  AuthRecoveryDeepLinkBridge? _authRecoveryDeepLinkBridge;
  bool _fullscreenEscapeHandlerRegistered = false;
  bool _startedInWindowsFullScreen = false;

  @override
  void initState() {
    super.initState();
    _authRecoveryDeepLinkBridge = AuthRecoveryDeepLinkBridge(
      navigateTo: (location) => ref.read(appRouterProvider).go(location),
      launchArgs: widget.launchArgs,
    );
    unawaited(_authRecoveryDeepLinkBridge!.start());
    unawaited(_setupWindowsFullScreenMode());
  }

  @override
  void dispose() {
    if (_fullscreenEscapeHandlerRegistered) {
      ServicesBinding.instance.keyboard.removeHandler(_handleGlobalKeyEvent);
      _fullscreenEscapeHandlerRegistered = false;
    }
    unawaited(_authRecoveryDeepLinkBridge?.dispose());
    super.dispose();
  }

  Future<void> _setupWindowsFullScreenMode() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) return;

    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(center: true);
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setFullScreen(true);
      _startedInWindowsFullScreen = true;
    });

    ServicesBinding.instance.keyboard.addHandler(_handleGlobalKeyEvent);
    _fullscreenEscapeHandlerRegistered = true;
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (!_startedInWindowsFullScreen) return false;
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey != LogicalKeyboardKey.escape) return false;

    _startedInWindowsFullScreen = false;
    unawaited(_exitFullScreenToMaximizedWindow());
    return true;
  }

  Future<void> _exitFullScreenToMaximizedWindow() async {
    final isFullScreen = await windowManager.isFullScreen();
    if (isFullScreen) {
      await windowManager.setFullScreen(false);
    }
    await windowManager.maximize();
    await windowManager.focus();
  }

  @override
  Widget build(BuildContext context) {
    // --- Global app state ---------------------------------------------------

    // Router configuration (navigation graph) provided by Riverpod.
    final router = ref.watch(appRouterProvider);

    // Current locale (selected language) for the whole app.
    final locale = ref.watch(app_state.currentLocaleProvider);

    // Dynamic accent color used to build both light & dark themes.
    final accentColor = ref.watch(app_state.currentAccentColorProvider);

    // --- MaterialApp configuration -----------------------------------------

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Movi',
      scrollBehavior: const MoviScrollBehavior(),
      theme: AppTheme.light(accentColor: accentColor),
      darkTheme: AppTheme.dark(accentColor: accentColor),
      // Politique produit actuelle: l'application fonctionne uniquement en dark.
      themeMode: ThemeMode.dark,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: _appLocalizationsDelegates,
      routerConfig: router,
      builder: (context, child) {
        return MoviRemoteNavigation(
          child: SubscriptionBootstrapper(
            child: LibraryCloudSyncBootstrapper(
              child: SeriesTrackingBootstrapper(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}
