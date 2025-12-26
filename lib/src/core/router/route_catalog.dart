import 'package:movi/src/core/router/app_route_paths.dart';

class AppRouteCatalog {
  static const List<String> criticalRoutes = [
    AppRoutePaths.launch,
    AppRoutePaths.authOtp,
    AppRoutePaths.bootstrap,
    AppRoutePaths.welcomeUser,
    AppRoutePaths.welcomeSources,
    AppRoutePaths.welcomeSourceSelect,
    AppRoutePaths.home,
  ];

  static const List<String> deepLinkRoutes = [
    AppRoutePaths.movieById,
    AppRoutePaths.tvById,
    AppRoutePaths.personById,
    AppRoutePaths.sagaDetailById,
    AppRoutePaths.player,
    AppRoutePaths.searchResults,
    AppRoutePaths.providerResults,
    AppRoutePaths.providerAllResults,
    AppRoutePaths.genreResults,
    AppRoutePaths.genreAllResults,
  ];
}
