import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/shared/domain/services/playback_resume_resolution.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';

class PlaybackHistoryReadState {
  const PlaybackHistoryReadState({
    required this.entry,
    required this.resumeResolution,
    this.isSeenOverride = false,
  });

  final HistoryEntry? entry;
  final PlaybackResumeResolution resumeResolution;
  final bool isSeenOverride;

  HistoryEntry? get resumableEntry {
    if (isSeenOverride) {
      return null;
    }
    return resumeResolution.canResume ? entry : null;
  }
}

final playbackHistoryReadStateProvider =
    FutureProvider.family<
      PlaybackHistoryReadState,
      ({String contentId, ContentType type})
    >((ref, params) async {
      final locator = ref.watch(slProvider);
      final historyRepo = locator<HistoryLocalRepository>();
      final userId = ref.watch(currentUserIdProvider);
      final entry = params.type == ContentType.series
          ? await historyRepo.getSeriesResumeState(
              params.contentId,
              userId: userId,
            )
          : await historyRepo.getEntry(
              params.contentId,
              params.type,
              userId: userId,
            );
      var isSeenOverride = false;
      if (params.type == ContentType.series &&
          locator.isRegistered<SeriesSeenStateRepository>()) {
        final seenStateRepo = locator<SeriesSeenStateRepository>();
        isSeenOverride =
            await seenStateRepo.getSeenState(
              params.contentId,
              userId: userId,
            ) !=
            null;
      }
      return PlaybackHistoryReadState(
        entry: entry,
        resumeResolution: resolvePlaybackResume(
          position: entry?.lastPosition,
          duration: entry?.duration,
        ),
        isSeenOverride: isSeenOverride,
      );
    });

final latestPlaybackHistoryEntryProvider =
    FutureProvider.family<
      HistoryEntry?,
      ({String contentId, ContentType type})
    >((ref, params) async {
      final state = await ref.watch(
        playbackHistoryReadStateProvider(params).future,
      );
      return state.entry;
    });

/// Entrée d'historique "en cours" pour un contenu donné (film ou série).
///
/// Un contenu est considéré "en cours" uniquement si:
/// - une durée est disponible
/// - et la progression est comprise entre 5% et 95% (seuils produit globaux)
final inProgressHistoryEntryProvider =
    FutureProvider.family<
      HistoryEntry?,
      ({String contentId, ContentType type})
    >((ref, params) async {
      final state = await ref.watch(
        playbackHistoryReadStateProvider(params).future,
      );
      return state.resumableEntry;
    });
