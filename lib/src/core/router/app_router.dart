// lib/src/core/router/app_router.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/features/welcome/presentation/pages/welcome_page.dart';
import 'package:movi/src/features/welcome/presentation/pages/splash_bootstrap_page.dart';
import 'package:movi/src/features/settings/presentation/pages/iptv_connect_page.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/library/presentation/pages/library_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/movie/presentation/pages/movie_detail_page.dart';
import '../../features/person/presentation/pages/person_detail_page.dart';
import '../../features/playlist/presentation/pages/playlist_detail_page.dart';
import '../../features/playlist/presentation/models/playlist_args.dart';
import '../../features/saga/presentation/pages/saga_detail_page.dart';
import '../../features/tv/presentation/pages/tv_detail_page.dart';

import '../di/injector.dart';
import '../storage/repositories/iptv_local_repository.dart';
import '../logging/logging_service.dart';

class AppRouteNames {
  static const launch = '/launch';
  static const welcome = '/welcome';
  static const bootstrap = '/bootstrap';
  static const home = '/';
  static const search = '/search';
  static const library = '/library';
  static const settings = '/settings';
  static const movie = '/movie';
  static const person = '/person';
  static const playlist = '/playlist';
  static const saga = '/saga';
  static const tv = '/tv';
}

final appRouter = GoRouter(
  initialLocation: AppRouteNames.launch,
  routes: [
    // --- LAUNCH GATE ---
    GoRoute(
      path: AppRouteNames.launch,
      name: 'launch',
      pageBuilder: (context, state) => const MaterialPage(child: _LaunchGate()),
    ),

    // --- WELCOME ---
    GoRoute(
      path: AppRouteNames.welcome,
      name: 'welcome',
      pageBuilder: (context, state) => const MaterialPage(child: WelcomePage()),
    ),

    // --- BOOTSTRAP (splash) ---
    GoRoute(
      path: AppRouteNames.bootstrap,
      name: 'bootstrap',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: SplashBootstrapPage(),
        transitionsBuilder: _fadeTransition,
      ),
    ),

    // --- HOME / TABS ---
    GoRoute(
      path: AppRouteNames.home,
      name: 'home',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: HomePage(),
        transitionsBuilder: _fadeTransition,
      ),
    ),
    GoRoute(
      path: AppRouteNames.search,
      name: 'search',
      pageBuilder: (context, state) => const MaterialPage(child: SearchPage()),
    ),
    GoRoute(
      path: AppRouteNames.library,
      name: 'library',
      pageBuilder: (context, state) => const MaterialPage(child: LibraryPage()),
    ),
    GoRoute(
      path: AppRouteNames.settings,
      name: 'settings',
      pageBuilder: (context, state) =>
          const MaterialPage(child: SettingsPage()),
    ),

    // --- DETAILS ---
    GoRoute(
      path: AppRouteNames.movie,
      name: 'movie_detail',
      pageBuilder: (context, state) =>
          const MaterialPage(child: MovieDetailPage()),
    ),
    GoRoute(
      path: AppRouteNames.person,
      name: 'person_detail',
      pageBuilder: (context, state) =>
          const MaterialPage(child: PersonDetailPage()),
    ),
    GoRoute(
      path: AppRouteNames.playlist,
      name: 'playlist_detail',
      pageBuilder: (context, state) {
        final args = state.extra is PlaylistDetailArgs
            ? state.extra as PlaylistDetailArgs
            : null;
        return MaterialPage(child: PlaylistDetailPage(args: args));
      },
    ),
    GoRoute(
      path: AppRouteNames.saga,
      name: 'saga_detail',
      pageBuilder: (context, state) =>
          const MaterialPage(child: SagaDetailPage()),
    ),
    GoRoute(
      path: AppRouteNames.tv,
      name: 'tv_detail',
      pageBuilder: (context, state) =>
          const MaterialPage(child: TvDetailPage()),
    ),

    // --- SETTINGS: IPTV CONNECT (toujours accessible depuis Settings)
    GoRoute(
      path: '/settings/iptv/connect',
      name: 'iptv_connect',
      pageBuilder: (context, state) =>
          const MaterialPage(child: IptvConnectPage()),
    ),
  ],
  errorPageBuilder: (context, state) => MaterialPage(
    child: Scaffold(
      body: Center(child: Text('Route introuvable: ${state.error}')),
    ),
  ),
);

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

/// Page de garde qui choisit Welcome vs Home au démarrage.
class _LaunchGate extends StatefulWidget {
  const _LaunchGate();

  @override
  State<_LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<_LaunchGate> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    // On lit le local repo pour vérifier s'il existe AU MOINS un compte IPTV
    final repo = sl<IptvLocalRepository>();
    final accounts = await repo.getAccounts();

    if (!mounted) return;
    if (accounts.isEmpty) {
      // Pas de compte → Welcome
      unawaited(LoggingService.log('LaunchGate: no accounts, go welcome'));
      GoRouter.of(context).go(AppRouteNames.welcome);
    } else {
      // Il y a un compte → Bootstrap (prépare avant Home)
      unawaited(LoggingService.log('LaunchGate: accounts found=${accounts.length}, go bootstrap'));
      GoRouter.of(context).go(AppRouteNames.bootstrap);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Splash minimal pendant la décision
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
