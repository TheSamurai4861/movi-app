import 'package:movi/src/core/parental/data/datasources/tmdb_content_rating_remote_data_source.dart';
import 'package:movi/src/core/parental/domain/repositories/content_rating_repository.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class CachedContentRatingRepository implements ContentRatingRepository {
  CachedContentRatingRepository(
    this._remote,
    this._cache, {
    CachePolicy policy = const CachePolicy(ttl: Duration(days: 7)),
  }) : _policy = policy;

  final TmdbContentRatingRemoteDataSource _remote;
  final ContentCacheRepository _cache;
  final CachePolicy _policy;

  String _key(ContentType type, int tmdbId, String region) =>
      'tmdb_min_age_${type.name}_${tmdbId}_$region';

  @override
  Future<ContentRatingResult> getMinAge({
    required ContentType type,
    required int tmdbId,
    List<String> preferredRegions = const <String>['BE', 'FR', 'US'],
  }) async {
    if (tmdbId <= 0) {
      return const ContentRatingResult(minAge: null, regionUsed: null, rawRating: null);
    }

    final normalizedRegions = preferredRegions
        .map((r) => r.trim().toUpperCase())
        .where((r) => r.isNotEmpty)
        .toList(growable: false);

    // 1) Cache hit (try every preferred region)
    for (final region in normalizedRegions) {
      final key = _key(type, tmdbId, region);
      final data = await _cache.getWithPolicy(key, _policy);
      if (data != null) {
        final minAge = _parseInt(data['min_age']);
        final raw = data['raw_rating']?.toString();
        if (minAge != null) {
          return ContentRatingResult(
            minAge: minAge,
            regionUsed: region,
            rawRating: raw,
          );
        }
      }
    }

    // 2) Remote fetch (once), pick best region BE -> FR -> US (or provided order)
    final Map<String, String> ratingsByRegion;
    if (type == ContentType.series) {
      ratingsByRegion = await _remote.fetchTvContentRatings(tmdbId);
    } else if (type == ContentType.movie) {
      ratingsByRegion = await _remote.fetchMovieReleaseCertifications(tmdbId);
    } else {
      return const ContentRatingResult(minAge: null, regionUsed: null, rawRating: null);
    }

    for (final region in normalizedRegions) {
      final raw = ratingsByRegion[region];
      if (raw == null || raw.trim().isEmpty) continue;

      final minAge = _parseMinAge(raw);
      if (minAge == null) continue;

      final key = _key(type, tmdbId, region);
      await _cache.put(
        key: key,
        type: 'tmdb_min_age',
        payload: <String, dynamic>{'min_age': minAge, 'raw_rating': raw, 'region': region},
      );
      return ContentRatingResult(minAge: minAge, regionUsed: region, rawRating: raw);
    }

    return const ContentRatingResult(minAge: null, regionUsed: null, rawRating: null);
  }
}

int? _parseMinAge(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;

  final upper = s.toUpperCase();

  // First: digits anywhere (handles "12", "12A", "MA15+", "TV-14", "PG-13"...)
  final match = RegExp(r'(\d{1,2})').firstMatch(upper);
  if (match != null) {
    final v = int.tryParse(match.group(1)!);
    if (v != null) return v;
  }

  // Common US movie ratings
  switch (upper) {
    case 'G':
    case 'U':
    case 'TV-G':
      return 0;
    case 'PG':
    case 'TV-PG':
      return 10;
    case 'R':
      return 17;
    case 'NC-17':
      return 17;
    case 'X':
      return 18;
  }

  // Common US TV ratings
  switch (upper) {
    case 'TV-Y':
      return 0;
    case 'TV-Y7':
      return 7;
    case 'TV-14':
      return 14;
    case 'TV-MA':
      return 17;
  }

  // Unrated / unknown
  switch (upper) {
    case 'NR':
    case 'N/A':
    case 'NA':
    case 'UNRATED':
    case 'NOT RATED':
      return null;
  }

  return null;
}

int? _parseInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}
