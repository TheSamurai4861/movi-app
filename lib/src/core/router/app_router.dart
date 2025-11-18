// lib/src/core/router/app_router.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/state/app_state.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/features/category_browser/presentation/models/category_args.dart';
import 'package:movi/src/features/category_browser/presentation/pages/category_page.dart';
import 'package:movi/src/features/home/presentation/pages/home_page.dart';
import 'package:movi/src/features/library/presentation/pages/library_page.dart';
import 'package:movi/src/features/movie/presentation/pages/movie_detail_page.dart';
import 'package:movi/src/features/person/presentation/pages/person_detail_page.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/features/player/presentation/pages/video_player_page.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/features/saga/presentation/pages/saga_detail_page.dart';
import 'package:movi/src/features/search/presentation/models/search_results_args.dart';
import 'package:movi/src/features/search/presentation/pages/search_page.dart';
import 'package:movi/src/features/search/presentation/pages/search_results_page.dart';
import 'package:movi/src/features/settings/presentation/pages/iptv_connect_page.dart';
import 'package:movi/src/features/settings/presentation/pages/settings_page.dart';
import 'package:movi/src/features/tv/presentation/pages/tv_detail_page.dart';
import 'package:movi/src/features/welcome/presentation/pages/splash_bootstrap_page.dart';
import 'package:movi/src/features/welcome/presentation/pages/welcome_user_page.dart';
import 'package:movi/src/core/models/models.dart';

class AppRouteNames {
  static const launch = '/launch';
  static const welcome = '/welcome';
  static const bootstrap = '/bootstrap';
  static const home = '/';
  static const search = '/search';
  static const searchResults = '/search_results';
  static const library = '/library';
  static const settings = '/settings';
  static const movie = '/movie';
  static const person = '/person';
  static const playlist = '/playlist';
  static const category = '/category';
  static const saga = '/saga';
  static const tv = '/tv';
  static const player = '/player';
}

GoRouter createRouter({
  required AppStateController appStateController,
  required AppLogger logger,
  required IptvLocalRepository iptvRepository,
}) => _RouterBundle(
  appStateController: appStateController,
  logger: logger,
  iptvRepository: iptvRepository,
).router;

final appRouterProvider = Provider<GoRouter>((ref) {
  final appStateController = ref.watch(appStateControllerProvider);
  final logger = ref.watch(slProvider)<AppLogger>();
  final iptvRepository = ref.watch(slProvider)<IptvLocalRepository>();

  final bundle = _RouterBundle(
    appStateController: appStateController,
    logger: logger,
    iptvRepository: iptvRepository,
  );

  ref.onDispose(() {
    bundle.router.dispose();
    bundle.launchGuard.dispose();
  });

  return bundle.router;
});

class _RouterBundle {
  _RouterBundle({
    required AppStateController appStateController,
    required AppLogger logger,
    required IptvLocalRepository iptvRepository,
  }) : launchGuard = _LaunchRedirectGuard(
         logger: logger,
         repository: iptvRepository,
         appStateController: appStateController,
       ) {
    router = GoRouter(
      initialLocation: AppRouteNames.launch,
      refreshListenable: launchGuard,
      redirect: launchGuard.handle,
      routes: [
        GoRoute(
          path: AppRouteNames.launch,
          name: 'launch',
          pageBuilder: (context, state) =>
              const MaterialPage(child: _LaunchGate()),
        ),
        GoRoute(
          path: AppRouteNames.welcome,
          name: 'welcome',
          pageBuilder: (context, state) =>
              const MaterialPage(child: WelcomeUserPage()),
        ),
        GoRoute(
          path: AppRouteNames.bootstrap,
          name: 'bootstrap',
          pageBuilder: (context, state) => const CustomTransitionPage(
            child: SplashBootstrapPage(),
            transitionsBuilder: _fadeTransition,
          ),
        ),
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
          pageBuilder: (context, state) =>
              const MaterialPage(child: SearchPage()),
        ),
        GoRoute(
          path: AppRouteNames.searchResults,
          name: 'search_results',
          pageBuilder: (context, state) {
            final args = state.extra is SearchResultsPageArgs
                ? state.extra as SearchResultsPageArgs
                : null;
            return MaterialPage(child: SearchResultsPage(args: args));
          },
        ),
        GoRoute(
          path: AppRouteNames.library,
          name: 'library',
          pageBuilder: (context, state) =>
              const MaterialPage(child: LibraryPage()),
        ),
        GoRoute(
          path: AppRouteNames.settings,
          name: 'settings',
          pageBuilder: (context, state) =>
              const MaterialPage(child: SettingsPage()),
        ),
        GoRoute(
          path: AppRouteNames.movie,
          name: 'movie_detail',
          pageBuilder: (context, state) {
            final media = state.extra is MoviMedia
                ? state.extra as MoviMedia
                : null;
            return CustomTransitionPage(
              child: MovieDetailPage(media: media),
              transitionsBuilder: _fadeTransition,
              transitionDuration: const Duration(milliseconds: 300),
              reverseTransitionDuration: const Duration(milliseconds: 300),
            );
          },
        ),
        GoRoute(
          path: AppRouteNames.person,
          name: 'person_detail',
          pageBuilder: (context, state) {
            final personSummary = state.extra is PersonSummary
                ? state.extra as PersonSummary
                : null;
            return MaterialPage(
              child: PersonDetailPage(personSummary: personSummary),
            );
          },
        ),
        GoRoute(
          path: AppRouteNames.category,
          name: 'category_page',
          pageBuilder: (context, state) {
            final args = state.extra is CategoryPageArgs
                ? state.extra as CategoryPageArgs
                : null;
            return MaterialPage(child: CategoryPage(args: args));
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
          pageBuilder: (context, state) {
            final media = state.extra is MoviMedia
                ? state.extra as MoviMedia
                : null;
            return CustomTransitionPage(
              child: TvDetailPage(media: media),
              transitionsBuilder: _fadeTransition,
              transitionDuration: const Duration(milliseconds: 300),
              reverseTransitionDuration: const Duration(milliseconds: 300),
            );
          },
        ),
        GoRoute(
          path: AppRouteNames.player,
          name: 'player',
          pageBuilder: (context, state) {
            final videoSource = state.extra is VideoSource
                ? state.extra as VideoSource
                : null;
            return MaterialPage(
              child: VideoPlayerPage(videoSource: videoSource),
            );
          },
        ),
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
  }

  late final GoRouter router;
  final _LaunchRedirectGuard launchGuard;
}

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

class _LaunchGate extends StatelessWidget {
  const _LaunchGate();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _LaunchRedirectGuard extends ChangeNotifier {
  _LaunchRedirectGuard({
    required this.logger,
    required this.repository,
    required AppStateController appStateController,
  }) : _appStateController = appStateController {
    // addListener renvoie une fonction pour se désabonner, qu'on stocke
    _removeAppStateListener = _appStateController.addListener(
      _handleAppStateChange,
    );
  }

  final AppLogger logger;
  final IptvLocalRepository repository;
  final AppStateController _appStateController;

  bool? _hasAccounts;
  bool _isResolving = false;

  /// Fonction retournée par `addListener` pour annuler l'écoute.
  late final void Function() _removeAppStateListener;

  FutureOr<String?> handle(BuildContext context, GoRouterState state) {
    final cached = _hasAccounts;

    if (cached == null) {
      _resolve();

      // subloc a été renommé en matchedLocation dans go_router >= 8.1.0
      // https://pub.dev/packages/go_router/changelog
      final currentLocation = state.matchedLocation;
      return currentLocation == AppRouteNames.launch
          ? null
          : AppRouteNames.launch;
    }

    final currentLocation = state.matchedLocation;

    if (!cached) {
      // Autoriser l’accès à la page de connexion IPTV même sans comptes
      final allowIptvConnect = currentLocation == '/settings/iptv/connect';
      if (currentLocation != AppRouteNames.welcome && !allowIptvConnect) {
        return AppRouteNames.welcome;
      }
    }

    if (cached &&
        (currentLocation == AppRouteNames.launch ||
            currentLocation == AppRouteNames.welcome)) {
      return AppRouteNames.bootstrap;
    }

    return null;
  }

  void _handleAppStateChange(AppState state) {
    if (state.activeIptvSources.isNotEmpty) {
      if (_hasAccounts != true) {
        _hasAccounts = true;
        notifyListeners();
      }
    } else if (_hasAccounts == true) {
      // on force une nouvelle résolution si les sources IPTV actives disparaissent
      _hasAccounts = null;
      notifyListeners();
    }
  }

  void _resolve() {
    if (_isResolving) return;
    _isResolving = true;

    repository
        .getAccounts()
        .then((accounts) => accounts.isNotEmpty)
        .then((value) {
          _hasAccounts = value;
        })
        .catchError((error, stackTrace) {
          logger.error('Launch redirect failed', error, stackTrace);
          _hasAccounts = false;
        })
        .whenComplete(() {
          _isResolving = false;
          notifyListeners();
        });
  }

  @override
  void dispose() {
    // On se désabonne du StateNotifier proprement
    _removeAppStateListener();
    super.dispose();
  }
}
