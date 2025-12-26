import 'dart:async';

import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

/// Service chargé de charger les backdrops pour les items de playlist.
///
/// Gère le chargement des images de fond depuis TMDB avec :
/// - Cache pour éviter les appels répétés
/// - Timeout pour éviter les chargements infinis
/// - Validation des URIs avant retour
abstract class PlaylistBackdropService {
  /// Charge le backdrop pour un [ContentReference].
  ///
  /// Retourne `null` si :
  /// - L'ID n'est pas un ID TMDB valide
  /// - Aucun backdrop n'est disponible
  /// - Une erreur survient lors du chargement
  Future<Uri?> getBackdrop(ContentReference reference);
}

/// Implémentation du service de chargement de backdrops pour les playlists.
class PlaylistBackdropServiceImpl implements PlaylistBackdropService {
  PlaylistBackdropServiceImpl({
    required TmdbClient tmdbClient,
    required TmdbImageResolver images,
  }) : _tmdbClient = tmdbClient,
       _images = images;

  final TmdbClient _tmdbClient;
  final TmdbImageResolver _images;

  // Cache simple pour éviter les appels répétés
  final Map<String, Uri?> _cache = {};

  @override
  Future<Uri?> getBackdrop(ContentReference reference) async {
    // Utiliser l'ID comme clé de cache
    final cacheKey = reference.id;

    // Vérifier le cache
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      final tmdbId = int.tryParse(reference.id);
      if (tmdbId == null) {
        _cache[cacheKey] = null;
        return null;
      }

      final isMovie = reference.type == ContentType.movie;

      // Ajouter un timeout pour éviter les chargements infinis
      final jsonImages = await _tmdbClient
          .getJson(
            isMovie ? 'movie/$tmdbId/images' : 'tv/$tmdbId/images',
            query: {'include_image_language': 'null'},
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw TimeoutException('Timeout loading backdrop images'),
          );

      final backdrops = jsonImages['backdrops'] as List<dynamic>?;
      if (backdrops == null || backdrops.isEmpty) {
        _cache[cacheKey] = null;
        return null;
      }

      // Sélectionner le backdrop avec iso_639_1 == null
      final noLangBackdrops = backdrops
          .whereType<Map<String, dynamic>>()
          .where((m) => m['iso_639_1'] == null)
          .toList();

      Uri? backdropUri;

      if (noLangBackdrops.isNotEmpty) {
        final backdropPath = noLangBackdrops.first['file_path']?.toString();
        if (backdropPath != null && backdropPath.isNotEmpty) {
          backdropUri = _images.backdrop(backdropPath, size: 'w780');
        }
      }

      // Fallback sur le premier backdrop disponible
      if (backdropUri == null) {
        final firstBackdrop = backdrops.first as Map<String, dynamic>?;
        final backdropPath = firstBackdrop?['file_path']?.toString();
        if (backdropPath != null && backdropPath.isNotEmpty) {
          backdropUri = _images.backdrop(backdropPath, size: 'w780');
        }
      }

      // Valider l'URI avant de le retourner
      if (backdropUri != null &&
          backdropUri.hasScheme &&
          backdropUri.hasAuthority) {
        _cache[cacheKey] = backdropUri;
        return backdropUri;
      }

      _cache[cacheKey] = null;
      return null;
    } on TimeoutException {
      _cache[cacheKey] = null;
      return null;
    } catch (_) {
      // Gérer les erreurs silencieusement
      _cache[cacheKey] = null;
      return null;
    }
  }
}
