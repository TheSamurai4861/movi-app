import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/features/library/domain/repositories/history_repository.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/features/library/library_constants.dart';
import 'package:movi/src/core/supabase/supabase_error_mapper.dart';

/// Remote implementation of [HistoryRepository] backed by Supabase.
///
/// Table: public.history
/// Colonnes principales:
/// - id uuid PK
/// - profile_id uuid (FK -> public.profiles.id)
/// - media_type text
/// - media_id text
/// - progress double precision (0..1)
/// - watched_at timestamptz
/// - created_at timestamptz
class SupabaseHistoryRepository implements HistoryRepository {
  const SupabaseHistoryRepository(this._client, {required this.profileId});

  final SupabaseClient _client;

  /// ID du profil courant (`public.profiles.id`).
  final String profileId;

  static const String _table = 'history';

  @override
  Future<List<ContentReference>> getCompleted() async {
    try {
      final rows = await _client
          .from(_table)
          .select()
          .eq('profile_id', profileId)
          .order('watched_at', ascending: false)
          .withConverter<List<Map<String, dynamic>>>(
            (data) => List<Map<String, dynamic>>.from(data as List),
          );

      final threshold = LibraryConstants.completedProgressThreshold;
      final filtered = rows.where((row) {
        final progress = (row['progress'] as num?)?.toDouble() ?? 0.0;
        return progress >= threshold;
      });

      return filtered
          .map(
            (row) => ContentReference(
              id: row['media_id'] as String,
              // Le titre affiché pourra être enrichi plus tard via TMDB/local.
              title: MediaTitle(row['media_id'] as String),
              type: _parseMediaType(row['media_type'] as String),
              poster: null,
            ),
          )
          .toList(growable: false);
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace: stackTrace);
    }
  }

  @override
  Future<List<ContentReference>> getInProgress() async {
    try {
      final rows = await _client
          .from(_table)
          .select()
          .eq('profile_id', profileId)
          .order('watched_at', ascending: false)
          .withConverter<List<Map<String, dynamic>>>(
            (data) => List<Map<String, dynamic>>.from(data as List),
          );

      final threshold = LibraryConstants.completedProgressThreshold;
      final filtered = rows.where((row) {
        final progress = (row['progress'] as num?)?.toDouble() ?? 0.0;
        return progress > 0 && progress < threshold;
      });

      return filtered
          .map(
            (row) => ContentReference(
              id: row['media_id'] as String,
              title: MediaTitle(row['media_id'] as String),
              type: _parseMediaType(row['media_type'] as String),
              poster: null,
            ),
          )
          .toList(growable: false);
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace: stackTrace);
    }
  }

  ContentType _parseMediaType(String raw) {
    switch (raw) {
      case 'movie':
        return ContentType.movie;
      case 'series':
        return ContentType.series;
      case 'saga':
        return ContentType.saga;
      case 'person':
        return ContentType.person;
      case 'playlist':
        return ContentType.playlist;
      default:
        return ContentType.movie;
    }
  }

  // Note: La synchronisation local ↔ remote est gérée par
  // [HybridPlaybackHistoryRepository] qui compose ce repository avec
  // le repository local (HistoryLocalRepository).
}
