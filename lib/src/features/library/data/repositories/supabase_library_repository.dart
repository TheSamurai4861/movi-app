import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/features/library/domain/repositories/library_repository.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/features/playlist/domain/entities/playlist.dart';
import 'package:movi/src/features/library/data/repositories/supabase_history_repository.dart';
import 'package:movi/src/core/supabase/supabase_error_mapper.dart';

/// Remote implementation of [LibraryRepository] backed by Supabase.
///
/// Tables utilisées:
/// - `public.favorites` pour les films/séries/sagas/personnes likés
/// - `public.history` pour l'historique de lecture (via [SupabaseHistoryRepository])
/// - `public.playlists` + `public.playlist_items` pour les playlists utilisateur
///
/// Schéma attendu pour `favorites`:
/// ```sql
/// CREATE TABLE public.favorites (
///   id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
///   profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
///   media_type text NOT NULL, -- 'movie', 'series', 'saga', 'person'
///   media_id text NOT NULL,
///   created_at timestamptz DEFAULT now(),
///   UNIQUE(profile_id, media_type, media_id)
/// );
/// ```
///
/// Schéma attendu pour `playlists`:
/// ```sql
/// CREATE TABLE public.playlists (
///   id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
///   profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
///   name text NOT NULL,
///   created_at timestamptz DEFAULT now()
/// );
///
/// CREATE TABLE public.playlist_items (
///   id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
///   playlist_id uuid REFERENCES public.playlists(id) ON DELETE CASCADE,
///   media_type text NOT NULL,
///   media_id text NOT NULL,
///   position int,
///   created_at timestamptz DEFAULT now()
/// );
/// ```
class SupabaseLibraryRepository implements LibraryRepository {
  const SupabaseLibraryRepository(this._client, {required this.profileId});

  final SupabaseClient _client;

  /// ID du profil courant (`public.profiles.id`).
  final String profileId;

  static const String _favoritesTable = 'favorites';
  static const String _playlistsTable = 'playlists';

  SupabaseHistoryRepository get _historyRepo =>
      SupabaseHistoryRepository(_client, profileId: profileId);

  /// Placeholder URI utilisé quand le poster est absent.
  static final Uri _placeholderPoster = Uri.parse(
    'https://via.placeholder.com/300x450?text=No+Poster',
  );

  @override
  Future<List<MovieSummary>> getLikedMovies() async {
    try {
      final rows = await _client
          .from(_favoritesTable)
          .select()
          .eq('profile_id', profileId)
          .eq('media_type', 'movie')
          .order('created_at', ascending: false);

      return (rows as List).map((row) {
        final map = row as Map<String, dynamic>;
        return MovieSummary(
          id: MovieId(map['media_id'] as String),
          tmdbId: _tryParseInt(map['media_id']),
          title: MediaTitle(map['media_id'] as String),
          poster: _placeholderPoster,
        );
      }).toList();
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace: stackTrace);
    }
  }

  @override
  Future<List<TvShowSummary>> getLikedShows() async {
    try {
      final rows = await _client
          .from(_favoritesTable)
          .select()
          .eq('profile_id', profileId)
          .eq('media_type', 'series')
          .order('created_at', ascending: false);

      return (rows as List).map((row) {
        final map = row as Map<String, dynamic>;
        return TvShowSummary(
          id: SeriesId(map['media_id'] as String),
          tmdbId: _tryParseInt(map['media_id']),
          title: MediaTitle(map['media_id'] as String),
          poster: _placeholderPoster,
        );
      }).toList();
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace: stackTrace);
    }
  }

  @override
  Future<List<SagaSummary>> getLikedSagas() async {
    try {
      final rows = await _client
          .from(_favoritesTable)
          .select()
          .eq('profile_id', profileId)
          .eq('media_type', 'saga')
          .order('created_at', ascending: false);

      return (rows as List).map((row) {
        final map = row as Map<String, dynamic>;
        return SagaSummary(
          id: SagaId(map['media_id'] as String),
          tmdbId: _tryParseInt(map['media_id']),
          title: MediaTitle(map['media_id'] as String),
          cover: null,
        );
      }).toList();
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace: stackTrace);
    }
  }

  @override
  Future<List<PersonSummary>> getLikedPersons() async {
    try {
      final rows = await _client
          .from(_favoritesTable)
          .select()
          .eq('profile_id', profileId)
          .eq('media_type', 'person')
          .order('created_at', ascending: false);

      return (rows as List).map((row) {
        final map = row as Map<String, dynamic>;
        return PersonSummary(
          id: PersonId(map['media_id'] as String),
          tmdbId: _tryParseInt(map['media_id']),
          name: map['media_id'] as String,
          photo: null,
        );
      }).toList();
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace: stackTrace);
    }
  }

  @override
  Future<List<ContentReference>> getHistoryCompleted() {
    return _historyRepo.getCompleted();
  }

  @override
  Future<List<ContentReference>> getHistoryInProgress() {
    return _historyRepo.getInProgress();
  }

  @override
  Future<List<PlaylistSummary>> getUserPlaylists(String userId) async {
    try {
      final rows = await _client
          .from(_playlistsTable)
          .select()
          .eq('profile_id', profileId)
          .order('created_at', ascending: false);

      return (rows as List).map((row) {
        final map = row as Map<String, dynamic>;
        return PlaylistSummary(
          id: PlaylistId(map['id'] as String),
          title: MediaTitle(map['name'] as String? ?? 'Playlist'),
          cover: null,
          isPinned: false,
          owner: profileId,
        );
      }).toList();
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace: stackTrace);
    }
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  /// Tente de parser un media_id en int (pour tmdbId).
  int? _tryParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
