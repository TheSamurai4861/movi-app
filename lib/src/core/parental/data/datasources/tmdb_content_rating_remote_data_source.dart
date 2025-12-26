import 'package:movi/src/core/network/network_failures.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';

/// Remote datasource: fetches content ratings from TMDB.
///
/// - Movie: `movie/{id}/release_dates`
/// - TV: `tv/{id}/content_ratings`
///
/// Returns a map `iso_3166_1 -> rawRating` (trimmed, non-empty).
class TmdbContentRatingRemoteDataSource {
  const TmdbContentRatingRemoteDataSource(this._client);

  final TmdbClient _client;

  Future<Map<String, String>> fetchMovieReleaseCertifications(int id) async {
    try {
      final json = await _client.getJson('movie/$id/release_dates');
      final results = json['results'];
      if (results is! List) return const <String, String>{};

      final out = <String, String>{};
      for (final item in results) {
        if (item is! Map) continue;
        final region = item['iso_3166_1']?.toString().trim().toUpperCase();
        if (region == null || region.isEmpty) continue;

        final releaseDates = item['release_dates'];
        if (releaseDates is! List) continue;

        for (final rd in releaseDates) {
          if (rd is! Map) continue;
          final cert = rd['certification']?.toString().trim();
          if (cert == null || cert.isEmpty) continue;

          // Store the first non-empty certification we see for the region.
          out.putIfAbsent(region, () => cert);
          break;
        }
      }
      return out;
    } on NotFoundFailure {
      // Gérer gracieusement les erreurs 404 (contenu inexistant ou sans ratings)
      return const <String, String>{};
    } catch (_) {
      // Pour toute autre erreur (timeout, connection, etc.), retourner une map vide
      // plutôt que de faire planter l'application
      return const <String, String>{};
    }
  }

  Future<Map<String, String>> fetchTvContentRatings(int id) async {
    try {
      final json = await _client.getJson('tv/$id/content_ratings');
      final results = json['results'];
      if (results is! List) return const <String, String>{};

      final out = <String, String>{};
      for (final item in results) {
        if (item is! Map) continue;
        final region = item['iso_3166_1']?.toString().trim().toUpperCase();
        if (region == null || region.isEmpty) continue;

        final rating = item['rating']?.toString().trim();
        if (rating == null || rating.isEmpty) continue;

        out.putIfAbsent(region, () => rating);
      }
      return out;
    } on NotFoundFailure {
      // Gérer gracieusement les erreurs 404 (contenu inexistant ou sans ratings)
      return const <String, String>{};
    } catch (_) {
      // Pour toute autre erreur (timeout, connection, etc.), retourner une map vide
      // plutôt que de faire planter l'application
      return const <String, String>{};
    }
  }
}

