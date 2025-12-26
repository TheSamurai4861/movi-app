// lib/src/core/router/app_route_ids.dart

/// Centralisation des **route names** GoRouter.
///
/// À utiliser avec `goNamed(...)` / `pushNamed(...)` et `namedLocation(...)`.
class AppRouteIds {
  static const launch = 'launch';
  static const welcome = 'welcome';
  static const welcomeUser = 'welcome_user';
  static const welcomeSources = 'welcome_sources';
  static const welcomeSourceSelect = 'welcome_sources_select';
  static const welcomeSourceLoading = 'welcome_sources_loading';
  static const authOtp = 'auth_otp';
  static const bootstrap = 'bootstrap';
  static const home = 'home';

  static const search = 'search';
  static const searchResults = 'search_results';
  static const providerResults = 'provider_results';
  static const providerAllResults = 'provider_all_results';
  static const genreResults = 'genre_results';
  static const genreAllResults = 'genre_all_results';

  static const library = 'library';
  static const libraryPlaylist = 'library_playlist_detail';

  static const pinRecovery = 'pin_recovery';

  static const settings = 'settings';
  static const about = 'about';
  static const iptvConnect = 'iptv_connect';
  static const iptvSources = 'iptv_sources';
  static const iptvSourceAdd = 'iptv_source_add';
  static const iptvSourceEdit = 'iptv_source_edit';
  static const iptvSourceOrganize = 'iptv_source_organize';

  static const movie = 'movie_detail';
  static const movieById = 'movie_detail_by_id';
  static const tv = 'tv_detail';
  static const tvById = 'tv_detail_by_id';
  static const person = 'person_detail';
  static const personById = 'person_detail_by_id';
  static const sagaDetail = 'saga_detail';
  static const sagaDetailById = 'saga_detail_by_id';
  static const category = 'category_page';
  static const player = 'player';
}
