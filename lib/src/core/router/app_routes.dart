// lib/src/core/router/app_routes.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/auth/presentation/widgets/auth_gate.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/src/core/router/app_route_ids.dart';
import 'package:movi/src/core/router/app_route_paths.dart';
import 'package:movi/src/core/router/launch_redirect_guard.dart';
import 'package:movi/src/core/router/not_found_page.dart';
import 'package:movi/src/core/widgets/overlay_splash.dart';
import 'package:movi/src/core/parental/presentation/pages/pin_recovery_page.dart';
import 'package:movi/src/features/auth/presentation/auth_otp_page.dart';
import 'package:movi/src/features/category_browser/presentation/models/category_args.dart';
import 'package:movi/src/features/category_browser/presentation/pages/category_page.dart';
import 'package:movi/src/features/library/presentation/pages/library_playlist_detail_page.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/features/movie/presentation/pages/movie_detail_page.dart';
import 'package:movi/src/features/person/presentation/pages/person_detail_page.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/features/player/presentation/pages/video_player_page.dart';
import 'package:movi/src/features/saga/presentation/pages/saga_detail_page.dart';
import 'package:movi/src/features/search/presentation/models/genre_all_results_args.dart';
import 'package:movi/src/features/search/presentation/models/genre_results_args.dart';
import 'package:movi/src/features/search/presentation/models/provider_all_results_args.dart';
import 'package:movi/src/features/search/presentation/models/provider_results_args.dart';
import 'package:movi/src/features/search/presentation/models/search_results_args.dart';
import 'package:movi/src/features/search/presentation/pages/genre_all_results_page.dart';
import 'package:movi/src/features/search/presentation/pages/genre_results_page.dart';
import 'package:movi/src/features/search/presentation/pages/provider_all_results_page.dart';
import 'package:movi/src/features/search/presentation/pages/provider_results_page.dart';
import 'package:movi/src/features/search/presentation/pages/search_results_page.dart';
import 'package:movi/src/features/settings/presentation/pages/about_page.dart';
import 'package:movi/src/features/settings/presentation/pages/iptv_connect_page.dart';
import 'package:movi/src/features/settings/presentation/pages/iptv_source_add_page.dart';
import 'package:movi/src/features/settings/presentation/pages/iptv_source_edit_page.dart';
import 'package:movi/src/features/settings/presentation/pages/iptv_source_organize_page.dart';
import 'package:movi/src/features/settings/presentation/pages/iptv_sources_page.dart';
import 'package:movi/src/features/tv/presentation/pages/tv_detail_page.dart';
import 'package:movi/src/features/welcome/presentation/pages/splash_bootstrap_page.dart';
import 'package:movi/src/features/welcome/presentation/pages/welcome_source_page.dart';
import 'package:movi/src/features/welcome/presentation/pages/welcome_source_select_page.dart';
import 'package:movi/src/features/welcome/presentation/pages/welcome_source_loading_page.dart';
import 'package:movi/src/features/welcome/presentation/pages/welcome_user_page.dart';
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/shared/presentation/router/content_route_args.dart';
import 'package:movi/src/core/router/route_args/player_route_args.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/shell/presentation/pages/app_shell_page.dart';

/// Construit la liste des routes de l'application.
///
/// Le [launchGuard] est pour l’instant uniquement utilisé comme
/// [refreshListenable] et dans la logique de redirection globale au
/// niveau du [GoRouter]. Il est néanmoins passé ici pour garder la
/// possibilité d'ajouter des redirections spécifiques par route à l’avenir.
List<RouteBase> buildAppRoutes(LaunchRedirectGuard launchGuard) {
  return [
    // --- Launch / welcome / bootstrap --------------------------------------
    GoRoute(
      path: AppRoutePaths.launch,
      name: AppRouteIds.launch,
      pageBuilder: (context, state) => const MaterialPage(child: _LaunchGate()),
    ),

    // Compat: /welcome -> /welcome/user
    GoRoute(
      path: AppRoutePaths.welcome,
      name: AppRouteIds.welcome,
      redirect: (context, state) => AppRoutePaths.welcomeUser,
      pageBuilder: (context, state) =>
          const MaterialPage(child: SizedBox.shrink()),
    ),

    // Étape 1: profil utilisateur
    GoRoute(
      path: AppRoutePaths.welcomeUser,
      name: AppRouteIds.welcomeUser,
      pageBuilder: (context, state) =>
          const MaterialPage(child: WelcomeUserPage()),
    ),

    // Étape 2: ajout/connexion des sources
    GoRoute(
      path: AppRoutePaths.welcomeSources,
      name: AppRouteIds.welcomeSources,
      pageBuilder: (context, state) =>
          const MaterialPage(child: WelcomeSourcePage()),
    ),

    // Étape 2bis: choix d'une source quand il y en a plusieurs (sans redemander le mot de passe).
    GoRoute(
      path: AppRoutePaths.welcomeSourceSelect,
      name: AppRouteIds.welcomeSourceSelect,
      pageBuilder: (context, state) =>
          const MaterialPage(child: WelcomeSourceSelectPage()),
    ),

    // Étape 2ter: chargement initial des playlists IPTV
    GoRoute(
      path: AppRoutePaths.welcomeSourceLoading,
      name: AppRouteIds.welcomeSourceLoading,
      pageBuilder: (context, state) =>
          const MaterialPage(child: WelcomeSourceLoadingPage()),
    ),

    GoRoute(
      path: AppRoutePaths.authOtp,
      name: AppRouteIds.authOtp,
      pageBuilder: (context, state) => const MaterialPage(child: AuthOtpPage()),
    ),

    GoRoute(
      path: AppRoutePaths.bootstrap,
      name: AppRouteIds.bootstrap,
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: SplashBootstrapPage(),
        transitionsBuilder: _fadeTransition,
      ),
    ),

    // --- Home (Shell) ------------------------------------------------------
GoRoute(
  path: AppRoutePaths.home,
  name: AppRouteIds.home,
  pageBuilder: (context, state) => const CustomTransitionPage(
    child: AuthGate(child: AppShellPage()),
    transitionsBuilder: _fadeTransition,
  ),
),

    // --- Recherche ---------------------------------------------------------
    GoRoute(
      path: AppRoutePaths.search,
      name: AppRouteIds.search,
      redirect: (context, state) => AppRoutePaths.home,
      pageBuilder: (context, state) =>
          const MaterialPage(child: SizedBox.shrink()),
    ),
    GoRoute(
      path: AppRoutePaths.searchResults,
      name: AppRouteIds.searchResults,
      pageBuilder: (context, state) {
        final args = state.extra is SearchResultsPageArgs
            ? state.extra as SearchResultsPageArgs
            : null;
        return MaterialPage(child: SearchResultsPage(args: args));
      },
    ),
    GoRoute(
      path: AppRoutePaths.providerResults,
      name: AppRouteIds.providerResults,
      pageBuilder: (context, state) {
        final args = state.extra is ProviderResultsArgs
            ? state.extra as ProviderResultsArgs
            : null;
        return MaterialPage(child: ProviderResultsPage(args: args));
      },
    ),
    GoRoute(
      path: AppRoutePaths.providerAllResults,
      name: AppRouteIds.providerAllResults,
      pageBuilder: (context, state) {
        final args = state.extra is ProviderAllResultsArgs
            ? state.extra as ProviderAllResultsArgs
            : null;

        if (args == null) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(
              message: l10n.notFoundWithEntity(l10n.entityProvider),
            ),
          );
        }

        return MaterialPage(
          child: ProviderAllResultsPage(args: args, type: args.type),
        );
      },
    ),
    GoRoute(
      path: AppRoutePaths.genreResults,
      name: AppRouteIds.genreResults,
      pageBuilder: (context, state) {
        final args = state.extra is GenreResultsArgs
            ? state.extra as GenreResultsArgs
            : null;
        return MaterialPage(child: GenreResultsPage(args: args));
      },
    ),
    GoRoute(
      path: AppRoutePaths.genreAllResults,
      name: AppRouteIds.genreAllResults,
      pageBuilder: (context, state) {
        final args = state.extra is GenreAllResultsArgs
            ? state.extra as GenreAllResultsArgs
            : null;

        if (args == null) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(message: l10n.notFoundWithEntity(l10n.entityGenre)),
          );
        }

        return MaterialPage(
          child: GenreAllResultsPage(args: args, type: args.type),
        );
      },
    ),

    // --- Bibliothèque ------------------------------------------------------
    GoRoute(
      path: AppRoutePaths.library,
      name: AppRouteIds.library,
      redirect: (context, state) => AppRoutePaths.home,
      pageBuilder: (context, state) =>
          const MaterialPage(child: SizedBox.shrink()),
    ),
    GoRoute(
      path: AppRoutePaths.libraryPlaylist,
      name: AppRouteIds.libraryPlaylist,
      pageBuilder: (context, state) {
        final playlist = state.extra is LibraryPlaylistItem
            ? state.extra as LibraryPlaylistItem
            : null;

        if (playlist == null) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(
              message: l10n.notFoundWithEntity(l10n.entityPlaylist),
            ),
          );
        }

        return MaterialPage(
          child: LibraryPlaylistDetailPage(playlist: playlist),
        );
      },
    ),

    GoRoute(
      path: AppRoutePaths.pinRecovery,
      name: AppRouteIds.pinRecovery,
      pageBuilder: (context, state) {
        final profileId = state.extra is String ? state.extra as String : null;
        return MaterialPage(
          child: PinRecoveryPage(profileId: profileId),
        );
      },
    ),

    // --- Paramètres --------------------------------------------------------
    GoRoute(
      path: AppRoutePaths.settings,
      name: AppRouteIds.settings,
      redirect: (context, state) => AppRoutePaths.home,
      pageBuilder: (context, state) =>
          const MaterialPage(child: SizedBox.shrink()),
    ),
    GoRoute(
      path: AppRoutePaths.about,
      name: AppRouteIds.about,
      pageBuilder: (context, state) =>
          const MaterialPage(child: AboutPage()),
    ),
    GoRoute(
      path: AppRoutePaths.iptvConnect,
      name: AppRouteIds.iptvConnect,
      pageBuilder: (context, state) =>
          const MaterialPage(child: IptvConnectPage()),
    ),
    GoRoute(
      path: AppRoutePaths.iptvSources,
      name: AppRouteIds.iptvSources,
      pageBuilder: (context, state) =>
          const MaterialPage(child: IptvSourcesPage()),
    ),
    GoRoute(
      path: AppRoutePaths.iptvSourceAdd,
      name: AppRouteIds.iptvSourceAdd,
      pageBuilder: (context, state) =>
          const MaterialPage(child: IptvSourceAddPage()),
    ),
    GoRoute(
      path: AppRoutePaths.iptvSourceEdit,
      name: AppRouteIds.iptvSourceEdit,
      pageBuilder: (context, state) {
        final accountId = state.extra is String ? state.extra as String : null;
        if (accountId == null || accountId.trim().isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(message: l10n.notFoundWithEntity(l10n.entitySource)),
          );
        }
        return MaterialPage(child: IptvSourceEditPage(accountId: accountId));
      },
    ),
    GoRoute(
      path: AppRoutePaths.iptvSourceOrganize,
      name: AppRouteIds.iptvSourceOrganize,
      pageBuilder: (context, state) {
        final accountId = state.extra is String ? state.extra as String : null;
        if (accountId == null || accountId.trim().isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(message: l10n.notFoundWithEntity(l10n.entitySource)),
          );
        }
        return MaterialPage(
          child: IptvSourceOrganizePage(accountId: accountId),
        );
      },
    ),

    // --- Détails contenus (films, séries, personnes, sagas, catégories) ----
    GoRoute(
      path: AppRoutePaths.movie,
      name: AppRouteIds.movie,
      pageBuilder: (context, state) {
        final extra = state.extra;
        final movieId = extra is ContentRouteArgs
            ? extra.id
            : extra is MoviMedia
                ? extra.id
                : null;

        if (movieId == null || movieId.trim().isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(message: l10n.notFoundWithEntity(l10n.entityMovie)),
          );
        }

        return CustomTransitionPage(
          child: MovieDetailPage(movieId: movieId),
          transitionsBuilder: _fadeTransition,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
      },
    ),
    GoRoute(
      path: AppRoutePaths.movieById,
      name: AppRouteIds.movieById,
      pageBuilder: (context, state) {
        final movieId = state.pathParameters['id'];
        if (movieId == null || movieId.trim().isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(message: l10n.notFoundWithEntity(l10n.entityMovie)),
          );
        }

        return CustomTransitionPage(
          child: MovieDetailPage(movieId: movieId),
          transitionsBuilder: _fadeTransition,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
      },
    ),
    GoRoute(
      path: AppRoutePaths.tv,
      name: AppRouteIds.tv,
      pageBuilder: (context, state) {
        final extra = state.extra;
        final seriesId = extra is ContentRouteArgs
            ? extra.id
            : extra is MoviMedia
                ? extra.id
                : null;

        if (seriesId == null || seriesId.trim().isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(message: l10n.notFoundWithEntity(l10n.entitySeries)),
          );
        }

        return CustomTransitionPage(
          child: TvDetailPage(seriesId: seriesId),
          transitionsBuilder: _fadeTransition,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
      },
    ),
    GoRoute(
      path: AppRoutePaths.tvById,
      name: AppRouteIds.tvById,
      pageBuilder: (context, state) {
        final seriesId = state.pathParameters['id'];
        if (seriesId == null || seriesId.trim().isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(message: l10n.notFoundWithEntity(l10n.entitySeries)),
          );
        }

        return CustomTransitionPage(
          child: TvDetailPage(seriesId: seriesId),
          transitionsBuilder: _fadeTransition,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
      },
    ),
    GoRoute(
      path: AppRoutePaths.person,
      name: AppRouteIds.person,
      pageBuilder: (context, state) {
        final personSummary = state.extra is PersonSummary
            ? state.extra as PersonSummary
            : null;

        if (personSummary == null) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(message: l10n.notFoundWithEntity(l10n.entityPerson)),
          );
        }

        return MaterialPage(
          child: PersonDetailPage(personSummary: personSummary),
        );
      },
    ),
    GoRoute(
      path: AppRoutePaths.personById,
      name: AppRouteIds.personById,
      pageBuilder: (context, state) {
        final personId = state.pathParameters['id'];
        if (personId == null || personId.trim().isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(message: l10n.notFoundWithEntity(l10n.entityPerson)),
          );
        }
        return MaterialPage(child: PersonDetailPage(personId: personId));
      },
    ),
    GoRoute(
      path: AppRoutePaths.category,
      name: AppRouteIds.category,
      pageBuilder: (context, state) {
        final args = state.extra is CategoryPageArgs
            ? state.extra as CategoryPageArgs
            : null;

        return MaterialPage(child: CategoryPage(args: args));
      },
    ),
    GoRoute(
      path: AppRoutePaths.sagaDetail,
      name: AppRouteIds.sagaDetail,
      pageBuilder: (context, state) {
        final sagaId = state.extra is String ? state.extra as String : null;

        if (sagaId == null || sagaId.trim().isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(message: l10n.notFoundWithEntity(l10n.entitySaga)),
          );
        }

        return MaterialPage(child: SagaDetailPage(sagaId: sagaId));
      },
    ),
    GoRoute(
      path: AppRoutePaths.sagaDetailById,
      name: AppRouteIds.sagaDetailById,
      pageBuilder: (context, state) {
        final sagaId = state.pathParameters['id'];

        if (sagaId == null || sagaId.trim().isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(message: l10n.notFoundWithEntity(l10n.entitySaga)),
          );
        }

        return MaterialPage(child: SagaDetailPage(sagaId: sagaId));
      },
    ),

    // --- Player ------------------------------------------------------------
    GoRoute(
      path: AppRoutePaths.player,
      name: AppRouteIds.player,
      pageBuilder: (context, state) {
        VideoSource? videoSource;
        final extra = state.extra;
        if (extra is VideoSource) {
          videoSource = extra;
        } else if (extra is PlayerRouteArgs) {
          videoSource = extra.toVideoSource();
        } else {
          final qp = state.uri.queryParameters;
          final url = qp['url']?.trim();
          if (url != null && url.isNotEmpty) {
            final resume = int.tryParse(qp['resumeSeconds'] ?? '');
            final season = int.tryParse(qp['season'] ?? '');
            final episode = int.tryParse(qp['episode'] ?? '');
            final poster = Uri.tryParse(qp['poster'] ?? '');
            final contentTypeRaw = (qp['contentType'] ?? '').trim();
            final contentType = switch (contentTypeRaw) {
              'movie' => ContentType.movie,
              'series' => ContentType.series,
              _ => null,
            };

            videoSource = PlayerRouteArgs(
              url: url,
              title: qp['title'],
              subtitle: qp['subtitle'],
              contentId: qp['contentId'],
              contentType: contentType,
              poster: poster?.toString().isEmpty == true ? null : poster,
              season: season,
              episode: episode,
              resumeSeconds: resume,
            ).toVideoSource();
          }
        }

        if (videoSource == null) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(message: l10n.notFoundWithEntity(l10n.entityVideo)),
          );
        }

        return MaterialPage(child: VideoPlayerPage(videoSource: videoSource));
      },
    ),
  ];
}

/// Transition simple en fondu réutilisée par plusieurs pages.
Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

/// Page de lancement minimaliste utilisée le temps que le guard
/// décide où envoyer l'utilisateur.
class _LaunchGate extends ConsumerStatefulWidget {
  const _LaunchGate();

  @override
  ConsumerState<_LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends ConsumerState<_LaunchGate> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(appLaunchRunnerProvider)('startup'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: OverlaySplash());
  }
}
