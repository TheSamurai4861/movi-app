import 'package:flutter/foundation.dart';

import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
import 'package:movi/src/features/library/data/repositories/supabase_playback_history_repository.dart';

/// Repository hybride qui écrit en local ET sur Supabase (si disponible).
///
/// Stratégie :
/// - **Local first** : toutes les écritures passent d'abord par le local (SQLite)
/// - **Sync async** : si Supabase est configuré, on synchronise en arrière-plan
/// - **Lecture locale** : on lit toujours depuis le local (source de vérité offline)
///
/// Les erreurs Supabase sont silencieusement ignorées pour ne pas bloquer l'UX.
class HybridPlaybackHistoryRepository implements PlaybackHistoryRepository {
  const HybridPlaybackHistoryRepository({
    required this.local,
    required this.defaultUserId,
    this.remote,
  });

  /// Repository local (SQLite) - toujours disponible.
  final HistoryLocalRepository local;

  /// User/profile id used when callers don't specify one.
  final String defaultUserId;

  /// Repository remote (Supabase) - nullable si non configuré.
  final SupabasePlaybackHistoryRepository? remote;

  @override
  Future<void> upsertPlay({
    required String contentId,
    required ContentType type,
    required String title,
    Uri? poster,
    DateTime? playedAt,
    Duration? position,
    Duration? duration,
    int? season,
    int? episode,
    String? userId,
  }) async {
    final resolvedUserId = (userId == null || userId.trim().isEmpty)
        ? defaultUserId
        : userId.trim();
    // 1. Écrire en local d'abord (priorité absolue)
    await local.upsertPlay(
      contentId: contentId,
      type: type,
      title: title,
      poster: poster,
      playedAt: playedAt,
      position: position,
      duration: duration,
      season: season,
      episode: episode,
      userId: resolvedUserId,
    );

    // 2. Synchroniser avec Supabase en arrière-plan (fire-and-forget)
    if (remote != null) {
      _syncToRemote(() => remote!.upsertPlay(
            contentId: contentId,
            type: type,
            title: title,
            poster: poster,
            playedAt: playedAt,
            position: position,
            duration: duration,
            season: season,
            episode: episode,
          ));
    }
  }

  @override
  Future<void> remove(String contentId, ContentType type, {String? userId}) async {
    final resolvedUserId = (userId == null || userId.trim().isEmpty)
        ? defaultUserId
        : userId.trim();
    // 1. Supprimer en local d'abord
    await local.remove(contentId, type, userId: resolvedUserId);

    // 2. Synchroniser avec Supabase en arrière-plan
    if (remote != null) {
      _syncToRemote(() => remote!.remove(contentId, type));
    }
  }

  @override
  Future<PlaybackHistoryEntry?> getEntry(
    String contentId,
    ContentType type, {
    int? season,
    int? episode,
    String? userId,
  }) async {
    final resolvedUserId = (userId == null || userId.trim().isEmpty)
        ? defaultUserId
        : userId.trim();
    // Lire depuis le local (source de vérité offline-first)
    final localEntry = await local.getEntry(
      contentId,
      type,
      season: season,
      episode: episode,
      userId: resolvedUserId,
    );

    if (localEntry == null) return null;

    return PlaybackHistoryEntry(
      contentId: localEntry.contentId,
      type: localEntry.type,
      title: localEntry.title,
      poster: localEntry.poster,
      lastPosition: localEntry.lastPosition,
      duration: localEntry.duration,
      season: localEntry.season,
      episode: localEntry.episode,
    );
  }

  /// Fire-and-forget sync vers Supabase avec gestion d'erreurs silencieuse.
  void _syncToRemote(Future<void> Function() action) {
    action().catchError((error, stackTrace) {
      // Log en debug uniquement, pas de crash utilisateur
      assert(() {
        debugPrint('[HybridPlaybackHistoryRepository] Supabase sync failed: $error');
        return true;
      }());
    });
  }
}







