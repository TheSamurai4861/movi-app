import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as app_state;
import 'package:movi/src/core/theme/theme.dart';
import 'package:movi/src/features/library/presentation/widgets/library_cloud_sync_bootstrapper.dart';
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
/// Because it is a [ConsumerWidget], it rebuilds automatically whenever
/// one of the watched providers (router, theme, locale, accent) changes.
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      theme: AppTheme.light(accentColor: accentColor),
      darkTheme: AppTheme.dark(accentColor: accentColor),
      themeMode: ThemeMode.dark,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: _appLocalizationsDelegates,
      routerConfig: router,
      builder: (context, child) {
        return LibraryCloudSyncBootstrapper(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
