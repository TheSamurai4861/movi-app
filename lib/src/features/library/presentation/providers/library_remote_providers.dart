import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/core/supabase/supabase_providers.dart';
import 'package:movi/src/core/profile/presentation/providers/selected_profile_providers.dart';
import 'package:movi/src/features/library/data/repositories/supabase_playback_history_repository.dart';
import 'package:movi/src/features/library/data/repositories/supabase_library_repository.dart';
import 'package:movi/src/features/library/data/repositories/supabase_favorites_repository.dart';
import 'package:movi/src/features/library/data/repositories/hybrid_playback_history_repository.dart';
import 'package:movi/src/features/library/domain/repositories/library_repository.dart';
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';

/// Helper : lève une erreur claire si aucun profil n'est sélectionné.
/// À utiliser uniquement dans des providers (jamais directement dans l'UI).
String requireProfileId(Ref ref) {
  final id = ref.watch(selectedProfileIdProvider);
  if (id == null || id.trim().isEmpty) {
    throw StateError('No selected profileId (SelectedProfileController not ready)');
  }
  return id.trim();
}

/// Repo remote de playback history (Supabase) pour le profil courant.
///
/// Utilise la table public.history et gère:
/// - upsertPlay / remove / getEntry pour un `profile_id` donné.
///
/// Retourne `null` si Supabase n'est pas configuré ou si aucun profil n'est
/// sélectionné. Cela permet de ne pas casser l'app quand le backend n'est
/// pas disponible (mode offline-first).
final supabasePlaybackHistoryRepositoryProvider =
    Provider<SupabasePlaybackHistoryRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final profileId = ref.watch(selectedProfileIdProvider);

  // Tant que Supabase ou le profil ne sont pas prêts, on renvoie null
  // pour ne pas casser l'app.
  if (client == null || profileId == null || profileId.trim().isEmpty) {
    return null;
  }

  return SupabasePlaybackHistoryRepository(
    client,
    profileId: profileId,
  );
});

/// Repo remote Library (Supabase) pour le profil courant.
///
/// Implémente toutes les méthodes de [LibraryRepository] :
/// - getLikedMovies / getLikedShows / getLikedSagas / getLikedPersons
/// - getHistoryCompleted / getHistoryInProgress
/// - getUserPlaylists
///
/// Retourne `null` si Supabase n'est pas configuré ou si aucun profil n'est
/// sélectionné.
final supabaseLibraryRepositoryProvider =
    Provider<LibraryRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final profileId = ref.watch(selectedProfileIdProvider);

  if (client == null || profileId == null || profileId.trim().isEmpty) {
    return null;
  }

  return SupabaseLibraryRepository(
    client,
    profileId: profileId,
  );
});

/// Repo remote Favorites (Supabase) pour le profil courant.
///
/// Permet de liker/unliker des contenus (films, séries, sagas, personnes)
/// et de vérifier si un contenu est dans les favoris.
///
/// Usage :
/// ```dart
/// final favRepo = ref.read(supabaseFavoritesRepositoryProvider);
/// if (favRepo != null) {
///   await favRepo.likeMovie(id: MovieId('123'), title: 'Mon Film', poster: uri);
///   final isLiked = await favRepo.isMovieLiked(MovieId('123'));
/// }
/// ```
///
/// Retourne `null` si Supabase n'est pas configuré ou si aucun profil n'est
/// sélectionné.
final supabaseFavoritesRepositoryProvider =
    Provider<SupabaseFavoritesRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final profileId = ref.watch(selectedProfileIdProvider);

  if (client == null || profileId == null || profileId.trim().isEmpty) {
    return null;
  }

  return SupabaseFavoritesRepository(
    client,
    profileId: profileId,
  );
});

// ---------------------------------------------------------------------------
// HYBRID REPOSITORY (LOCAL + SUPABASE)
// ---------------------------------------------------------------------------

/// Repository hybride pour l'historique de lecture.
///
/// Ce provider combine le repository local (SQLite) avec le repository
/// Supabase (si disponible). Il implémente une stratégie **local-first** :
/// - Les écritures passent toujours par le local en premier
/// - Si Supabase est configuré et qu'un profil est sélectionné, la sync
///   se fait en arrière-plan (fire-and-forget)
/// - Les lectures utilisent le local comme source de vérité
///
/// Usage dans le player ou ailleurs :
/// ```dart
/// final repo = ref.read(hybridPlaybackHistoryRepositoryProvider);
/// await repo.upsertPlay(...);
/// ```
final hybridPlaybackHistoryRepositoryProvider =
    Provider<PlaybackHistoryRepository>((ref) {
  // Repository local (toujours disponible via le service locator)
  final local = ref.watch(slProvider)<HistoryLocalRepository>();
  final userId = ref.watch(currentUserIdProvider);

  // Repository Supabase (peut être null si pas configuré)
  final remote = ref.watch(supabasePlaybackHistoryRepositoryProvider);

  return HybridPlaybackHistoryRepository(
    local: local,
    defaultUserId: userId,
    remote: remote,
  );
});

