import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

/// Service chargé d'enrichir un [ContentReference] avec des métadonnées TMDB.
///
/// Actuellement, il se concentre sur l'ajout de l'année (`year`) lorsque
/// celle-ci est absente, en interrogeant l'API TMDB via [TmdbClient].
class PlaylistTmdbEnrichmentService {
  PlaylistTmdbEnrichmentService(this._tmdbClient);

  final TmdbClient _tmdbClient;

  /// Enrichit un [ContentReference] en lui ajoutant une année si possible.
  ///
  /// - Si `reference.year` est déjà renseigné, la référence est retournée telle
  ///   quelle (aucun appel réseau).
  /// - Sinon, on tente de parser `reference.id` comme un identifiant TMDB et on
  ///   interroge l'API `movie/{id}` ou `tv/{id}` selon [ContentReference.type].
  Future<ContentReference> enrichYear(ContentReference reference) async {
    if (reference.year != null) return reference;

    final tmdbId = int.tryParse(reference.id);
    if (tmdbId == null) return reference;

    try {
      int? year;

      switch (reference.type) {
        case ContentType.movie:
          year = await _fetchMovieYear(tmdbId);
          break;
        case ContentType.series:
          year = await _fetchTvYear(tmdbId);
          break;
        default:
          // Pour l'instant, seuls films et séries sont supportés.
          return reference;
      }

      if (year != null) {
        return reference.copyWith(year: Optional.of(year));
      }
    } catch (_) {
      // En cas d'erreur réseau ou de parsing, on renvoie la référence telle
      // quelle pour ne pas casser le flux d'affichage.
    }

    return reference;
  }

  Future<int?> _fetchMovieYear(int tmdbId) async {
    final json = await _tmdbClient.getJson('movie/$tmdbId');
    final releaseDate = json['release_date']?.toString();
    return _parseYear(releaseDate);
  }

  Future<int?> _fetchTvYear(int tmdbId) async {
    final json = await _tmdbClient.getJson('tv/$tmdbId');
    final firstAirDate = json['first_air_date']?.toString();
    return _parseYear(firstAirDate);
  }

  int? _parseYear(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('-');
    if (parts.isEmpty) return null;
    return int.tryParse(parts[0]);
  }
}

/// Helper pour récupérer le [PlaylistTmdbEnrichmentService] depuis le service
/// locator global. Utilisé lorsque l'on ne souhaite pas introduire un provider
/// dédié.
PlaylistTmdbEnrichmentService get playlistTmdbEnrichmentService =>
    PlaylistTmdbEnrichmentService(sl<TmdbClient>());
