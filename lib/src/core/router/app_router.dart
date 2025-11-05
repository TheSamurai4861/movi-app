import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/library/presentation/pages/library_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/movie/presentation/pages/movie_detail_page.dart';
import '../../features/person/presentation/pages/person_detail_page.dart';
import '../../features/playlist/presentation/pages/playlist_detail_page.dart';
import '../../features/saga/presentation/pages/saga_detail_page.dart';
import '../../features/tv/presentation/pages/tv_detail_page.dart';

class AppRouteNames {
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
  routes: [
    GoRoute(
      path: AppRouteNames.home,
      name: 'home',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: HomePage(),
      ),
    ),
    GoRoute(
      path: AppRouteNames.search,
      name: 'search',
      pageBuilder: (context, state) => const MaterialPage(
        child: SearchPage(),
      ),
    ),
    GoRoute(
      path: AppRouteNames.library,
      name: 'library',
      pageBuilder: (context, state) => const MaterialPage(
        child: LibraryPage(),
      ),
    ),
    GoRoute(
      path: AppRouteNames.settings,
      name: 'settings',
      pageBuilder: (context, state) => const MaterialPage(
        child: SettingsPage(),
      ),
    ),
    GoRoute(
      path: AppRouteNames.movie,
      name: 'movie_detail',
      pageBuilder: (context, state) => const MaterialPage(
        child: MovieDetailPage(),
      ),
    ),
    GoRoute(
      path: AppRouteNames.person,
      name: 'person_detail',
      pageBuilder: (context, state) => const MaterialPage(
        child: PersonDetailPage(),
      ),
    ),
    GoRoute(
      path: AppRouteNames.playlist,
      name: 'playlist_detail',
      pageBuilder: (context, state) => const MaterialPage(
        child: PlaylistDetailPage(),
      ),
    ),
    GoRoute(
      path: AppRouteNames.saga,
      name: 'saga_detail',
      pageBuilder: (context, state) => const MaterialPage(
        child: SagaDetailPage(),
      ),
    ),
    GoRoute(
      path: AppRouteNames.tv,
      name: 'tv_detail',
      pageBuilder: (context, state) => const MaterialPage(
        child: TvDetailPage(),
      ),
    ),
  ],
  errorPageBuilder: (context, state) => MaterialPage(
    child: Scaffold(
      body: Center(
        child: Text('Route introuvable: ${state.error}'),
      ),
    ),
  ),
);
