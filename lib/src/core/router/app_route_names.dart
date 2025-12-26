// lib/src/core/router/app_route_names.dart

import 'package:movi/src/core/router/app_route_paths.dart';

/// Compat: centralisation historique des **paths**.
///
/// Utiliser plutôt :
/// - [AppRoutePaths] pour les URLs (go/push)
/// - `AppRouteIds` pour les route names GoRouter (goNamed/pushNamed)
///
/// Note: ce fichier reste volontairement non-déprécié pour éviter de créer
/// une vague de warnings; migration progressive recommandée.
class AppRouteNames {
  static const launch = AppRoutePaths.launch;

  /// Compat : route historique. À garder le temps de migrer.
  /// Idéalement, /welcome redirige vers /welcome/user dans app_routes.dart.
  static const welcome = AppRoutePaths.welcome;

  /// Nouvelles étapes distinctes du flow welcome.
  static const welcomeUser = AppRoutePaths.welcomeUser;
  static const welcomeSources = AppRoutePaths.welcomeSources;
  static const welcomeSourceSelect = AppRoutePaths.welcomeSourceSelect;
  static const welcomeSourceLoading = AppRoutePaths.welcomeSourceLoading;

  static const bootstrap = AppRoutePaths.bootstrap;

  static const home = AppRoutePaths.home;

  static const authOtp = AppRoutePaths.authOtp;

  static const search = AppRoutePaths.search;
  static const searchResults = AppRoutePaths.searchResults;
  static const providerResults = AppRoutePaths.providerResults;
  static const providerAllResults = AppRoutePaths.providerAllResults;
  static const genreResults = AppRoutePaths.genreResults;
  static const genreAllResults = AppRoutePaths.genreAllResults;

  static const library = AppRoutePaths.library;
  static const libraryPlaylist = AppRoutePaths.libraryPlaylist;

  static const pinRecovery = AppRoutePaths.pinRecovery;

  static const settings = AppRoutePaths.settings;
  static const iptvConnect = AppRoutePaths.iptvConnect;
  static const iptvSources = AppRoutePaths.iptvSources;
  static const iptvSourceAdd = AppRoutePaths.iptvSourceAdd;
  static const iptvSourceEdit = AppRoutePaths.iptvSourceEdit;
  static const iptvSourceOrganize = AppRoutePaths.iptvSourceOrganize;

  static const movie = AppRoutePaths.movie;
  static const movieById = AppRoutePaths.movieById;
  static const tv = AppRoutePaths.tv;
  static const tvById = AppRoutePaths.tvById;
  static const person = AppRoutePaths.person;
  static const personById = AppRoutePaths.personById;
  static const sagaDetail = AppRoutePaths.sagaDetail;
  static const sagaDetailById = AppRoutePaths.sagaDetailById;
  static const category = AppRoutePaths.category;
  static const player = AppRoutePaths.player;
}
