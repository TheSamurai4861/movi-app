import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/features/library/domain/repositories/favorites_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/core/supabase/supabase_error_mapper.dart';

/// Remote implementation of [FavoritesRepository] backed by Supabase.
///
/// Table: public.favorites
/// Colonnes:
/// - id uuid PK (auto-generated)
/// - profile_id uuid (FK -> public.profiles.id)
/// - media_type text ('movie', 'series', 'saga', 'person')
/// - media_id text
/// - created_at timestamptz
///
/// La contrainte UNIQUE(profile_id, media_type, media_id) permet les upserts.
class SupabaseFavoritesRepository implements FavoritesRepository {
  const SupabaseFavoritesRepository(
    this._client, {
    required this.profileId,
  });

  final SupabaseClient _client;

  /// ID du profil courant (`public.profiles.id`).
  final String profileId;

  static const String _table = 'favorites';

  // ---------------------------------------------------------------------------
  // PERSONS
  // ---------------------------------------------------------------------------

  @override
  Future<void> likePerson({
    required PersonId id,
    required String name,
    Uri? photo,
  }) async {
    await _upsertFavorite(
      mediaType: 'person',
      mediaId: id.value,
    );
  }

  @override
  Future<void> unlikePerson(PersonId id) async {
    await _removeFavorite(mediaType: 'person', mediaId: id.value);
  }

  // ---------------------------------------------------------------------------
  // MOVIES
  // ---------------------------------------------------------------------------

  /// Ajoute un film aux favoris.
  Future<void> likeMovie({
    required MovieId id,
    required String title,
    Uri? poster,
  }) async {
    await _upsertFavorite(
      mediaType: 'movie',
      mediaId: id.value,
    );
  }

  /// Retire un film des favoris.
  Future<void> unlikeMovie(MovieId id) async {
    await _removeFavorite(mediaType: 'movie', mediaId: id.value);
  }

  /// Vérifie si un film est dans les favoris.
  Future<bool> isMovieLiked(MovieId id) async {
    return _isFavorite(mediaType: 'movie', mediaId: id.value);
  }

  // ---------------------------------------------------------------------------
  // SERIES
  // ---------------------------------------------------------------------------

  /// Ajoute une série aux favoris.
  Future<void> likeSeries({
    required SeriesId id,
    required String title,
    Uri? poster,
  }) async {
    await _upsertFavorite(
      mediaType: 'series',
      mediaId: id.value,
    );
  }

  /// Retire une série des favoris.
  Future<void> unlikeSeries(SeriesId id) async {
    await _removeFavorite(mediaType: 'series', mediaId: id.value);
  }

  /// Vérifie si une série est dans les favoris.
  Future<bool> isSeriesLiked(SeriesId id) async {
    return _isFavorite(mediaType: 'series', mediaId: id.value);
  }

  // ---------------------------------------------------------------------------
  // SAGAS
  // ---------------------------------------------------------------------------

  /// Ajoute une saga aux favoris.
  Future<void> likeSaga({
    required SagaId id,
    required String title,
    Uri? cover,
  }) async {
    await _upsertFavorite(
      mediaType: 'saga',
      mediaId: id.value,
    );
  }

  /// Retire une saga des favoris.
  Future<void> unlikeSaga(SagaId id) async {
    await _removeFavorite(mediaType: 'saga', mediaId: id.value);
  }

  /// Vérifie si une saga est dans les favoris.
  Future<bool> isSagaLiked(SagaId id) async {
    return _isFavorite(mediaType: 'saga', mediaId: id.value);
  }

  // ---------------------------------------------------------------------------
  // GENERIC CONTENT REFERENCE (pour compatibilité avec ContentType)
  // ---------------------------------------------------------------------------

  /// Ajoute un contenu aux favoris via ContentReference.
  Future<void> likeContent(ContentReference ref) async {
    await _upsertFavorite(
      mediaType: ref.type.name,
      mediaId: ref.id,
    );
  }

  /// Retire un contenu des favoris.
  Future<void> unlikeContent(String mediaId, ContentType type) async {
    await _removeFavorite(mediaType: type.name, mediaId: mediaId);
  }

  /// Vérifie si un contenu est dans les favoris.
  Future<bool> isContentLiked(String mediaId, ContentType type) async {
    return _isFavorite(mediaType: type.name, mediaId: mediaId);
  }

  // ---------------------------------------------------------------------------
  // PRIVATE HELPERS
  // ---------------------------------------------------------------------------

  Future<void> _upsertFavorite({
    required String mediaType,
    required String mediaId,
  }) async {
    try {
      await _client.from(_table).upsert(
        <String, Object?>{
          'profile_id': profileId,
          'media_type': mediaType,
          'media_id': mediaId,
        },
        onConflict: 'profile_id,media_type,media_id',
      );
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace: stackTrace);
    }
  }

  Future<void> _removeFavorite({
    required String mediaType,
    required String mediaId,
  }) async {
    try {
      await _client.from(_table).delete().match(<String, Object>{
        'profile_id': profileId,
        'media_type': mediaType,
        'media_id': mediaId,
      });
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace: stackTrace);
    }
  }

  Future<bool> _isFavorite({
    required String mediaType,
    required String mediaId,
  }) async {
    try {
      final result = await _client
          .from(_table)
          .select('id')
          .eq('profile_id', profileId)
          .eq('media_type', mediaType)
          .eq('media_id', mediaId)
          .maybeSingle();
      return result != null;
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace: stackTrace);
    }
  }
}
