import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/shared/domain/constants/playback_progress_thresholds.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';

/// Entrée d'historique "en cours" pour un contenu donné (film ou série).
///
/// Un contenu est considéré "en cours" uniquement si:
/// - une durée est disponible
/// - et la progression est comprise entre 5% et 95% (seuils produit globaux)
final inProgressHistoryEntryProvider =
    FutureProvider.family<HistoryEntry?, ({String contentId, ContentType type})>(
      (ref, params) async {
        final historyRepo = ref.watch(slProvider)<HistoryLocalRepository>();
        final userId = ref.watch(currentUserIdProvider);
        final entries = await historyRepo.readAll(params.type, userId: userId);

        try {
          final entry = entries.firstWhere((e) => e.contentId == params.contentId);

          final duration = entry.duration;
          if (duration == null || duration.inSeconds <= 0) return null;

          final positionSeconds = entry.lastPosition?.inSeconds ?? 0;
          final progress = positionSeconds / duration.inSeconds;

          if (progress >= PlaybackProgressThresholds.minInProgress &&
              progress < PlaybackProgressThresholds.maxInProgress) {
            return entry;
          }

          return null;
        } catch (_) {
          return null;
        }
      },
    );
