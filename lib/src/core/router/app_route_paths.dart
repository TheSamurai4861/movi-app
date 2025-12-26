// lib/src/core/router/app_route_paths.dart

/// Centralisation des **paths** de navigation (URLs) de l'application.
///
/// À utiliser avec `context.go(...)` / `context.push(...)`.
class AppRoutePaths {
  static const launch = '/launch';

  /// Compat : route historique. À garder le temps de migrer.
  /// Idéalement, /welcome redirige vers /welcome/user dans app_routes.dart.
  static const welcome = '/welcome';

  /// Nouvelles étapes distinctes du flow welcome.
  static const welcomeUser = '/welcome/user';
  static const welcomeSources = '/welcome/sources';
  static const welcomeSourceSelect = '/welcome/sources/select';
  static const welcomeSourceLoading = '/welcome/sources/loading';

  static const bootstrap = '/bootstrap';

  static const home = '/';

  static const authOtp = '/auth/otp';

  static const search = '/search';
  static const searchResults = '/search_results';
  static const providerResults = '/provider_results';
  static const providerAllResults = '/provider_all_results';
  static const genreResults = '/genre_results';
  static const genreAllResults = '/genre_all_results';

  static const library = '/library';
  static const libraryPlaylist = '/library/playlist';

  static const pinRecovery = '/pin/recovery';

  static const settings = '/settings';
  static const about = '/settings/about';
  static const iptvConnect = '/settings/iptv/connect';
  static const iptvSources = '/settings/iptv/sources';
  static const iptvSourceAdd = '/settings/iptv/sources/add';
  static const iptvSourceEdit = '/settings/iptv/sources/edit';
  static const iptvSourceOrganize = '/settings/iptv/sources/organize';

  static const movie = '/movie';
  static const movieById = '/movie/:id';
  static const tv = '/tv';
  static const tvById = '/tv/:id';
  static const person = '/person';
  static const personById = '/person/:id';
  static const sagaDetail = '/saga/detail';
  static const sagaDetailById = '/saga/detail/:id';
  static const category = '/category';
  static const player = '/player';
}
