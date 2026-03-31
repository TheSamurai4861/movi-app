import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/core/router/router.dart';
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
import 'package:movi/src/core/subscription/domain/entities/premium_feature.dart';
import 'package:movi/src/core/subscription/presentation/providers/subscription_providers.dart';
import 'package:movi/src/features/settings/presentation/widgets/premium_feature_locked_sheet.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/core/utils/unawaited.dart';

Future<bool> _guardParental(
  BuildContext context,
  WidgetRef ref, {
  required ContentRouteArgs args,
}) async {
  // Xtream IDs cannot be evaluated reliably here.
  if (args.isXtream) {
    return true;
  }
  if (args.type != ContentType.movie && args.type != ContentType.series) {
    return true;
  }

  final profile = ref.read(currentProfileProvider);
  if (profile == null) {
    return true;
  }

  final hasRestrictions = profile.isKid || profile.pegiLimit != null;
  if (!hasRestrictions) {
    return true;
  }

  final content = ContentReference(
    id: args.id,
    type: args.type,
    title: MediaTitle(args.id),
  );

  final decision = await ref.read(
    parental.contentAgeDecisionProvider(content).future,
  );
  if (decision.isAllowed) {
    return true;
  }

  if (!context.mounted) {
    return false;
  }
  final unlocked = await RestrictedContentSheet.show(
    context,
    ref,
    profile: profile,
    reason: decision.reason,
  );
  return unlocked;
}

Future<bool> _guardPremiumFeature(
  BuildContext context,
  WidgetRef ref, {
  required PremiumFeature feature,
}) async {
  final hasPremium = await ref.read(
    canAccessPremiumFeatureProvider(feature).future,
  );
  if (hasPremium) return true;
  if (!context.mounted) return false;
  await showPremiumFeatureLockedSheet(context);
  return false;
}

Future<void> navigateToPersonDetail(
  BuildContext context,
  WidgetRef ref, {
  required PersonSummary person,
}) async {
  final allowed = await _guardPremiumFeature(
    context,
    ref,
    feature: PremiumFeature.extendedDiscoveryDetails,
  );
  if (!allowed || !context.mounted) return;
  context.push(AppRouteNames.person, extra: person);
}

Future<void> navigateToSagaDetail(
  BuildContext context,
  WidgetRef ref, {
  required String sagaId,
}) async {
  final allowed = await _guardPremiumFeature(
    context,
    ref,
    feature: PremiumFeature.extendedDiscoveryDetails,
  );
  if (!allowed || !context.mounted) return;
  context.push(AppRouteNames.sagaDetail, extra: sagaId);
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
  if (!allowed) {
    return;
  }
  if (!context.mounted) return;

  // Pour les films IPTV (`xtream:*`), la page de détail gère le fallback / matching TMDB.
  // On évite ici un "enrichissement TMDB" bloquant (et inutile) qui provoque un overlay.
  if (args.isXtream) {
    if (context.mounted) {
      context.push(AppRouteNames.movie, extra: args);
    }
    return;
  }

  // Déclencher l'enrichissement en arrière-plan, sans overlay de pré-navigation.
  // L'overlay (placeholder) est géré par la page détails elle-même.
  unawaited(
    ref
        .read(mdp.movieDetailEnrichmentProvider(args.id).future)
        .timeout(const Duration(seconds: 20))
        .catchError((e, st) {
      logger.log(
        LogLevel.warn,
        '🔵 [NAV] Enrichissement (background) movie.id=${args.id} a échoué: $e',
        category: 'navigation',
        error: e,
        stackTrace: st is StackTrace ? st : null,
      );
      return false;
    }),
  );

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

  // Déclencher l'enrichissement en arrière-plan, sans overlay de pré-navigation.
  // L'overlay (placeholder) est géré par la page détails elle-même.
  unawaited(
    ref
        .read(tvdp.tvDetailEnrichmentProvider(args.id).future)
        .timeout(const Duration(seconds: 20))
        .catchError((e, st) {
      logger.log(
        LogLevel.warn,
        '🟢 [NAV] Enrichissement (background) tv.id=${args.id} a échoué: $e',
        category: 'navigation',
        error: e,
        stackTrace: st is StackTrace ? st : null,
      );
      return false;
    }),
  );

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
