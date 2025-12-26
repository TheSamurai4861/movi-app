import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/core/supabase/supabase_error_mapper.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';

/// Remote implementation of [PlaybackHistoryRepository] backed by Supabase.
///
/// Table: public.history
/// Colonnes utilisées:
/// - profile_id uuid (FK -> public.profiles.id)
/// - media_type text
/// - media_id text
/// - progress double precision (0..1)
/// - watched_at timestamptz
/// - created_at timestamptz
class SupabasePlaybackHistoryRepository implements PlaybackHistoryRepository {
  const SupabasePlaybackHistoryRepository(
    this._client, {
    required this.profileId,
  });

  final SupabaseClient _client;

  /// ID du profil courant (`public.profiles.id`).
  final String profileId;

  static const String _table = 'history';

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
    final now = (playedAt ?? DateTime.now()).toUtc();

    final double? progress;
    if (position == null || duration == null || duration.inMilliseconds <= 0) {
      progress = null;
    } else {
      final ratio = position.inMilliseconds / duration.inMilliseconds;
      if (ratio.isNaN || ratio.isInfinite) {
        progress = null;
      } else if (ratio < 0) {
        progress = 0.0;
      } else if (ratio > 1) {
        progress = 1.0;
      } else {
        progress = ratio;
      }
    }

    try {
      // Contrainte UNIQUE(profile_id, media_type, media_id) recommandée.
      await _client.from(_table).upsert(
        <String, Object?>{
          'profile_id': profileId,
          'media_type': type.name,
          'media_id': contentId,
          'progress': progress,
          'watched_at': now.toIso8601String(),
          // Champs optionnels pour restaurer Continue Watching sur un autre device.
          'title': title,
          'poster': poster?.toString(),
          'last_position_seconds': position?.inSeconds,
          'duration_seconds': duration?.inSeconds,
          'season': season,
          'episode': episode,
          'deleted_at': null,
        },
        onConflict: 'profile_id,media_type,media_id',
      );
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> remove(String contentId, ContentType type, {String? userId}) async {
    try {
      await _client.from(_table).delete().match(<String, Object>{
        'profile_id': profileId,
        'media_type': type.name,
        'media_id': contentId,
      });
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace: stackTrace);
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
    try {
      final builder = _client
          .from(_table)
          .select()
          .eq('profile_id', profileId)
          .eq('media_type', type.name)
          .eq('media_id', contentId);

      final row = await builder.maybeSingle();
      if (row == null) return null;

      final map = row;

      return PlaybackHistoryEntry(
        contentId: map['media_id'] as String,
        type: type,
        title: '',
      );
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace: stackTrace);
    }
  }
}
