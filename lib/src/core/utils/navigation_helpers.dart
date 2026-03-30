import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/widgets/overlay_splash.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/features/movie/presentation/providers/movie_detail_providers.dart'
    as mdp;
import 'package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart'
    as tvdp;
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/presentation/router/content_route_args.dart';
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/core/parental/presentation/widgets/restricted_content_sheet.dart';

Future<bool> _guardParental(
  BuildContext context,
  WidgetRef ref, {
  required ContentRouteArgs args,
}) async {
  // Xtream IDs cannot be evaluated reliably here.
  if (args.isXtream) return true;
  if (args.type != ContentType.movie && args.type != ContentType.series)
    return true;

  final profile = ref.read(currentProfileProvider);
  if (profile == null) return true;

  final hasRestrictions = profile.isKid || profile.pegiLimit != null;
  if (!hasRestrictions) return true;

  final content = ContentReference(
    id: args.id,
    type: args.type,
    title: MediaTitle(args.id),
  );

  final decision = await ref.read(
    parental.contentAgeDecisionProvider(content).future,
  );
  if (decision.isAllowed) return true;

  if (!context.mounted) return false;
  final unlocked = await RestrictedContentSheet.show(
    context,
    ref,
    profile: profile,
    reason: decision.reason,
  );
  return unlocked;
}

/// Navigue vers la page de détails d'un film avec vérification d'enrichissement.
///
/// Affiche un indicateur de chargement si un enrichissement est nécessaire,
/// puis navigue une fois terminé.
Future<void> navigateToMovieDetail(
  BuildContext context,
  WidgetRef ref,
  ContentRouteArgs args,
) async {
  final logger = sl<AppLogger>();
  logger.debug(
    '🔵 [NAV] navigateToMovieDetail appelé pour id=${args.id}, type=${args.type}',
    category: 'navigation',
  );

  if (args.type != ContentType.movie) {
    logger.warn(
      '🔵 [NAV] navigateToMovieDetail appelé avec type inattendu: ${args.type} (id=${args.id})',
      category: 'navigation',
    );
  }

  // Parental gate (tap guard)
  final allowed = await _guardParental(context, ref, args: args);
  if (!allowed) return;
  if (!context.mounted) return;

  // Pour les films IPTV (`xtream:*`), la page de détail gère le fallback / matching TMDB.
  // On évite ici un "enrichissement TMDB" bloquant (et inutile) qui provoque un overlay.
  if (args.isXtream) {
    if (context.mounted) {
      context.push(AppRouteNames.movie, extra: args);
    }
    return;
  }

  // Vérifier si un enrichissement est nécessaire en déclenchant le provider
  final enrichmentAsync = ref.read(mdp.movieDetailEnrichmentProvider(args.id));
  logger.debug(
    '🔵 [NAV] movieDetailEnrichmentProvider lu, état: isLoading=${enrichmentAsync.isLoading}, hasValue=${enrichmentAsync.hasValue}, hasError=${enrichmentAsync.hasError}',
    category: 'navigation',
  );

  // Si le provider est en chargement, afficher un overlay et attendre
  if (enrichmentAsync.isLoading) {
    logger.debug(
      '🔵 [NAV] Provider en chargement, affichage overlay et attente enrichissement pour movie.id=${args.id}',
      category: 'navigation',
    );
    // Afficher un overlay de chargement
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const OverlaySplash(),
    );
    // Attendre que l'enrichissement soit terminé (avec timeout pour éviter blocage infini)
    try {
      final result = await ref
          .read(mdp.movieDetailEnrichmentProvider(args.id).future)
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              logger.log(
                LogLevel.warn,
                '🔵 [NAV] Timeout lors de l\'attente enrichissement pour movie.id=${args.id} (20s), navigation continue',
                category: 'navigation',
              );
              return false; // Retourner false pour continuer la navigation
            },
          );
      logger.debug(
        '🔵 [NAV] Enrichissement terminé pour movie.id=${args.id}, needsEnrichment=$result',
        category: 'navigation',
      );
    } catch (e, st) {
      logger.log(
        LogLevel.warn,
        '🔵 [NAV] Erreur lors de l\'enrichissement pour movie.id=${args.id}: $e, navigation continue',
        category: 'navigation',
        error: e,
        stackTrace: st,
      );
      // En cas d'erreur, on continue quand même la navigation
    } finally {
      // Fermer l'overlay
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  } else {
    logger.debug(
      '🔵 [NAV] Provider pas en chargement, traitement état pour movie.id=${args.id}',
      category: 'navigation',
    );
    // Si pas en chargement, attendre quand même le résultat pour s'assurer
    // que l'enrichissement est fait si nécessaire
    await enrichmentAsync.when(
      loading: () async {
        logger.debug(
          '🔵 [NAV] État loading dans when() pour movie.id=${args.id}',
          category: 'navigation',
        );
        // Ne devrait pas arriver ici, mais au cas où
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const OverlaySplash(),
        );
        try {
          final result = await ref.read(
            mdp.movieDetailEnrichmentProvider(args.id).future,
          );
          logger.debug(
            '🔵 [NAV] Enrichissement terminé (dans when loading) pour movie.id=${args.id}, needsEnrichment=$result',
            category: 'navigation',
          );
        } finally {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      error: (error, stackTrace) {
        logger.log(
          LogLevel.warn,
          '🔵 [NAV] Erreur dans provider pour movie.id=${args.id}: $error',
          category: 'navigation',
          error: error,
          stackTrace: stackTrace,
        );
        // En cas d'erreur, naviguer quand même
      },
      data: (needsEnrichment) {
        logger.debug(
          '🔵 [NAV] Données disponibles pour movie.id=${args.id}, needsEnrichment=$needsEnrichment',
          category: 'navigation',
        );
        // Si un enrichissement était nécessaire, il a déjà été fait
      },
    );
  }

  // Naviguer vers la page de détails
  if (context.mounted) {
    logger.debug(
      '🔵 [NAV] Navigation vers page détails movie pour id=${args.id}',
      category: 'navigation',
    );
    context.push(AppRouteNames.movie, extra: args);
  } else {
    logger.warn(
      '🔵 [NAV] Context non monté, navigation annulée pour movie.id=${args.id}',
      category: 'navigation',
    );
  }
}

/// Navigue vers la page de détails d'une série avec vérification d'enrichissement.
///
/// Affiche un indicateur de chargement si un enrichissement est nécessaire,
/// puis navigue une fois terminé. Charge également les épisodes Xtream
/// en arrière-plan.
Future<void> navigateToTvDetail(
  BuildContext context,
  WidgetRef ref,
  ContentRouteArgs args,
) async {
  final logger = sl<AppLogger>();
  logger.debug(
    '🟢 [NAV] navigateToTvDetail appelé pour id=${args.id}, type=${args.type}',
    category: 'navigation',
  );

  // Parental gate (tap guard)
  final allowed = await _guardParental(context, ref, args: args);
  if (!allowed) return;
  if (!context.mounted) return;

  // Vérifier si un enrichissement est nécessaire en déclenchant le provider
  final enrichmentAsync = ref.read(tvdp.tvDetailEnrichmentProvider(args.id));
  logger.debug(
    '🟢 [NAV] tvDetailEnrichmentProvider lu, état: isLoading=${enrichmentAsync.isLoading}, hasValue=${enrichmentAsync.hasValue}, hasError=${enrichmentAsync.hasError}',
    category: 'navigation',
  );

  // Si le provider est en chargement, afficher un overlay et attendre
  if (enrichmentAsync.isLoading) {
    logger.debug(
      '🟢 [NAV] Provider en chargement, affichage overlay et attente enrichissement pour tv.id=${args.id}',
      category: 'navigation',
    );
    // Afficher un overlay de chargement
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const OverlaySplash(),
    );
    // Attendre que l'enrichissement soit terminé (avec timeout pour éviter blocage infini)
    try {
      final result = await ref
          .read(tvdp.tvDetailEnrichmentProvider(args.id).future)
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              logger.log(
                LogLevel.warn,
                '🟢 [NAV] Timeout lors de l\'attente enrichissement pour tv.id=${args.id} (20s), navigation continue',
                category: 'navigation',
              );
              return false; // Retourner false pour continuer la navigation
            },
          );
      logger.debug(
        '🟢 [NAV] Enrichissement terminé pour tv.id=${args.id}, needsEnrichment=$result',
        category: 'navigation',
      );
    } catch (e, st) {
      logger.log(
        LogLevel.warn,
        '🟢 [NAV] Erreur lors de l\'enrichissement pour tv.id=${args.id}: $e, navigation continue',
        category: 'navigation',
        error: e,
        stackTrace: st,
      );
      // En cas d'erreur, on continue quand même la navigation
    } finally {
      // Fermer l'overlay
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  } else {
    logger.debug(
      '🟢 [NAV] Provider pas en chargement, traitement état pour tv.id=${args.id}',
      category: 'navigation',
    );
    // Si pas en chargement, attendre quand même le résultat pour s'assurer
    // que l'enrichissement est fait si nécessaire
    await enrichmentAsync.when(
      loading: () async {
        logger.debug(
          '🟢 [NAV] État loading dans when() pour tv.id=${args.id}',
          category: 'navigation',
        );
        // Ne devrait pas arriver ici, mais au cas où
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const OverlaySplash(),
        );
        try {
          final result = await ref.read(
            tvdp.tvDetailEnrichmentProvider(args.id).future,
          );
          logger.debug(
            '🟢 [NAV] Enrichissement terminé (dans when loading) pour tv.id=${args.id}, needsEnrichment=$result',
            category: 'navigation',
          );
        } finally {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      error: (error, stackTrace) {
        logger.log(
          LogLevel.warn,
          '🟢 [NAV] Erreur dans provider pour tv.id=${args.id}: $error',
          category: 'navigation',
          error: error,
          stackTrace: stackTrace,
        );
        // En cas d'erreur, naviguer quand même
      },
      data: (needsEnrichment) {
        logger.debug(
          '🟢 [NAV] Données disponibles pour tv.id=${args.id}, needsEnrichment=$needsEnrichment',
          category: 'navigation',
        );
        // Si un enrichissement était nécessaire, il a déjà été fait
      },
    );
  }

  // Naviguer vers la page de détails
  if (context.mounted) {
    logger.debug(
      '🟢 [NAV] Navigation vers page détails tv pour id=${args.id}',
      category: 'navigation',
    );
    context.push(AppRouteNames.tv, extra: args);
  } else {
    logger.warn(
      '🟢 [NAV] Context non monté, navigation annulée pour tv.id=${args.id}',
      category: 'navigation',
    );
  }
}
