import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/utils/title_cleaner.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
import 'package:movi/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart';
import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_detail_dto.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/domain/services/similarity_service.dart';

/// Service utilitaire pour résoudre les IDs TMDB à partir de différentes sources.
///
/// Fournit des méthodes pour rechercher des IDs TMDB via :
/// - Recherche par titre avec similarité
/// - Recherche par IMDB ID (si disponible)
/// - Recherche améliorée avec métadonnées multiples (rating, overview, runtime)
class TmdbIdResolverService {
  TmdbIdResolverService({
    required TmdbMovieRemoteDataSource moviesRemote,
    required TmdbTvRemoteDataSource tvRemote,
    required TmdbClient tmdbClient,
    required SimilarityService similarity,
    required AppLogger logger,
  })  : _moviesRemote = moviesRemote,
        _tvRemote = tvRemote,
        _tmdbClient = tmdbClient,
        _similarity = similarity,
        _logger = logger;

  final TmdbMovieRemoteDataSource _moviesRemote;
  final TmdbTvRemoteDataSource _tvRemote;
  final TmdbClient _tmdbClient;
  final SimilarityService _similarity;
  final AppLogger _logger;
  static final Set<String> _stopWords = <String>{
    'the',
    'a',
    'an',
    'of',
    'and',
    'le',
    'la',
    'les',
    'de',
    'du',
    'des',
  };

  /// Recherche un ID TMDB pour un film par titre.
  ///
  /// Utilise la similarité de titre et l'année pour trouver le meilleur match.
  /// Retourne `null` si aucun match suffisant n'est trouvé (seuil >= 0.6).
  Future<int?> searchTmdbIdByTitleForMovie({
    required String title,
    int? releaseYear,
    String? language,
  }) async {
    try {
      final candidates = _buildCandidates(title, releaseYear);
      if (candidates.isEmpty) return null;

      double bestScore = 0.0;
      int? bestMatchId;
      String? bestCandidate;
      String? bestReason;
      int? bestYear;

      for (final candidate in candidates) {
        final searchResults = await _moviesRemote.searchMovies(
          candidate.query,
          language: language,
          page: 1,
        );
        if (searchResults.isEmpty) continue;

        for (final result in searchResults) {
          final score = _similarity.score(candidate.cleanedTitle, result.title);
          final (adjustedScore, threshold, matchedYear) = _scoreWithYearBias(
            score: score,
            targetYear: candidate.year,
            rawDate: result.releaseDate,
          );

          if (adjustedScore >= threshold && adjustedScore > bestScore) {
            bestScore = adjustedScore;
            bestMatchId = result.id;
            bestCandidate = candidate.query;
            bestReason = candidate.reason;
            bestYear = matchedYear;
          }
        }
      }

      if (bestMatchId != null) {
        _logger.debug(
          'Found TMDB match for movie "$title": tmdbId=$bestMatchId (score=$bestScore, candidate="$bestCandidate", reason=$bestReason, yearMatch=$bestYear)',
          category: 'tmdb_id_resolver',
        );
        return bestMatchId;
      }

      return null;
    } catch (e) {
      _logger.warn(
        'Error searching TMDB for movie "$title": $e',
        category: 'tmdb_id_resolver',
      );
      return null;
    }
  }

  /// Recherche un ID TMDB pour une série par titre.
  ///
  /// Utilise la similarité de titre et l'année pour trouver le meilleur match.
  /// Retourne `null` si aucun match suffisant n'est trouvé (seuil >= 0.6).
  Future<int?> searchTmdbIdByTitleForTv({
    required String title,
    int? releaseYear,
    String? language,
  }) async {
    try {
      final candidates = _buildCandidates(title, releaseYear);
      if (candidates.isEmpty) return null;

      double bestScore = 0.0;
      int? bestMatchId;
      String? bestCandidate;
      String? bestReason;
      int? bestYear;

      for (final candidate in candidates) {
        final searchResults = await _tvRemote.searchShows(
          candidate.query,
          language: language,
          page: 1,
        );
        if (searchResults.isEmpty) continue;

        for (final result in searchResults) {
          final score = _similarity.score(candidate.cleanedTitle, result.name);
          final (adjustedScore, threshold, matchedYear) = _scoreWithYearBias(
            score: score,
            targetYear: candidate.year,
            rawDate: result.firstAirDate,
          );

          if (adjustedScore >= threshold && adjustedScore > bestScore) {
            bestScore = adjustedScore;
            bestMatchId = result.id;
            bestCandidate = candidate.query;
            bestReason = candidate.reason;
            bestYear = matchedYear;
          }
        }
      }

      if (bestMatchId != null) {
        _logger.debug(
          'Found TMDB match for TV show "$title": tmdbId=$bestMatchId (score=$bestScore, candidate="$bestCandidate", reason=$bestReason, yearMatch=$bestYear)',
          category: 'tmdb_id_resolver',
        );
        return bestMatchId;
      }

      return null;
    } catch (e) {
      _logger.warn(
        'Error searching TMDB for TV show "$title": $e',
        category: 'tmdb_id_resolver',
      );
      return null;
    }
  }

  /// Recherche un ID TMDB par IMDB ID.
  ///
  /// Utilise l'API TMDB `find/{external_id}` avec `external_source=imdb_id`.
  /// Retourne l'ID TMDB du film ou de la série si trouvé.
  Future<int?> searchTmdbIdByImdbId(String imdbId) async {
    try {
      if (imdbId.trim().isEmpty) return null;

      final json = await _tmdbClient.getJson(
        'find/$imdbId',
        query: {'external_source': 'imdb_id'},
      );

      // TMDB retourne movie_results et tv_results
      final movieResults = json['movie_results'] as List<dynamic>? ?? [];
      final tvResults = json['tv_results'] as List<dynamic>? ?? [];

      // Prioriser les films, puis les séries
      if (movieResults.isNotEmpty) {
        final firstMovie = movieResults.first as Map<String, dynamic>?;
        final id = firstMovie?['id'] as int?;
        if (id != null) {
          _logger.debug(
            'Found TMDB movie ID via IMDB: imdbId=$imdbId, tmdbId=$id',
            category: 'tmdb_id_resolver',
          );
          return id;
        }
      }

      if (tvResults.isNotEmpty) {
        final firstTv = tvResults.first as Map<String, dynamic>?;
        final id = firstTv?['id'] as int?;
        if (id != null) {
          _logger.debug(
            'Found TMDB TV ID via IMDB: imdbId=$imdbId, tmdbId=$id',
            category: 'tmdb_id_resolver',
          );
          return id;
        }
      }

      return null;
    } catch (e) {
      _logger.warn(
        'Error searching TMDB by IMDB ID "$imdbId": $e',
        category: 'tmdb_id_resolver',
      );
      return null;
    }
  }

  /// Recherche améliorée avec métadonnées multiples pour un item Xtream.
  ///
  /// Utilise le titre, l'année, le rating, et optionnellement l'overview
  /// pour améliorer la précision de la recherche.
  ///
  /// Le seuil de similarité est ajusté dynamiquement :
  /// - 0.6 par défaut
  /// - 0.65 si plusieurs métadonnées correspondent (année + rating)
  Future<int?> enhancedSearchTmdbId({
    required XtreamPlaylistItem item,
    required String language,
  }) async {
    // D'abord essayer IMDB si disponible
    if (item.imdbId != null && item.imdbId!.trim().isNotEmpty) {
      final imdbResult = await searchTmdbIdByImdbId(item.imdbId!);
      if (imdbResult != null) {
        _logger.debug(
          'Found TMDB ID via IMDB for "${item.title}": imdbId=${item.imdbId}, tmdbId=$imdbResult',
          category: 'tmdb_id_resolver',
        );
        return imdbResult;
      }
    }

    // Ensuite recherche par titre
    final isMovie = item.type == XtreamPlaylistItemType.movie;

    final searchResults = isMovie
        ? await _moviesRemote.searchMovies(
            TitleCleaner.cleanWithYear(item.title).cleanedTitle,
            language: language,
            page: 1,
          )
        : await _tvRemote.searchShows(
            TitleCleaner.cleanWithYear(item.title).cleanedTitle,
            language: language,
            page: 1,
          );

    if (searchResults.isEmpty) return null;

    final cleaned = TitleCleaner.cleanWithYear(item.title);
    final targetYear = cleaned.year ?? item.releaseYear;

    double bestScore = 0.0;
    int? bestMatchId;
    int metadataMatches = 0; // Compte les métadonnées qui correspondent

    for (final result in searchResults) {
      final resultTitle = isMovie
          ? (result as TmdbMovieSummaryDto).title
          : (result as TmdbTvSummaryDto).name;
      final score = _similarity.score(cleaned.cleanedTitle, resultTitle);

      var adjustedScore = score;
      var matches = 0;

      // Vérifier l'année
      if (targetYear != null) {
        final resultDate = isMovie
            ? (result as TmdbMovieSummaryDto).releaseDate
            : (result as TmdbTvSummaryDto).firstAirDate;
        if (resultDate != null) {
          try {
            final resultYear = DateTime.parse(resultDate).year;
            if (resultYear == targetYear) {
              adjustedScore = (adjustedScore + 0.1).clamp(0.0, 1.0);
              matches++;
            }
          } catch (_) {
            // ignore erreurs parsing
          }
        }
      }

      // Vérifier le rating (si disponible)
      if (item.rating != null) {
        final resultRating = isMovie
            ? (result as TmdbMovieSummaryDto).voteAverage
            : (result as TmdbTvSummaryDto).voteAverage;
        if (resultRating != null) {
          // Bonus si la différence de rating est < 1.0
          final ratingDiff = (item.rating! - resultRating).abs();
          if (ratingDiff < 1.0) {
            adjustedScore = (adjustedScore + 0.05).clamp(0.0, 1.0);
            matches++;
          }
        }
      }

      // Ajuster le seuil si plusieurs métadonnées correspondent
      final threshold = matches >= 2 ? 0.65 : 0.6;

      if (adjustedScore >= threshold && adjustedScore > bestScore) {
        bestScore = adjustedScore;
        bestMatchId = isMovie
            ? (result as TmdbMovieSummaryDto).id
            : (result as TmdbTvSummaryDto).id;
        metadataMatches = matches;
      }
    }

    if (bestMatchId != null) {
      _logger.debug(
        'Found enhanced TMDB match for "${item.title}": tmdbId=$bestMatchId (score=$bestScore, metadataMatches=$metadataMatches)',
        category: 'tmdb_id_resolver',
      );
      return bestMatchId;
    }

    return null;
  }

  List<_SearchCandidate> _buildCandidates(String title, int? releaseYear) {
    final cleaned = TitleCleaner.cleanWithYear(title);
    final baseTitle = cleaned.cleanedTitle;
    if (baseTitle.isEmpty) return const [];

    final year = cleaned.year ?? releaseYear;
    final tokens = baseTitle.split(' ').where((t) => t.isNotEmpty).toList();
    final tokensWithoutYear = tokens.where((t) => !_isYearToken(t)).toList();
    final tokensWithoutStopWords = tokens
        .where((t) => !_stopWords.contains(t.toLowerCase()) && t.length > 2)
        .toList();

    final seen = <String>{};
    final candidates = <_SearchCandidate>[];

    void addCandidate(String query, String reason, int? candidateYear) {
      final normalized = query.toLowerCase().trim();
      if (normalized.isEmpty || seen.contains(normalized)) return;
      seen.add(normalized);
      candidates.add(
        _SearchCandidate(
          query: query,
          cleanedTitle: query,
          year: candidateYear,
          reason: reason,
        ),
      );
    }

    addCandidate(baseTitle, 'cleaned', year);

    if (tokensWithoutYear.isNotEmpty &&
        tokensWithoutYear.join(' ') != baseTitle) {
      addCandidate(tokensWithoutYear.join(' '), 'no_year_token', year);
    }

    if (tokensWithoutStopWords.isNotEmpty &&
        tokensWithoutStopWords.join(' ') != baseTitle) {
      addCandidate(tokensWithoutStopWords.join(' '), 'principal_tokens', year);
    }

    if (tokens.length > 4) {
      addCandidate(tokens.take(4).join(' '), 'leading_tokens', year);
    }

    final subtitleSplit = baseTitle.split(RegExp(r'[:—-]'));
    if (subtitleSplit.length > 1) {
      final head = subtitleSplit.first.trim();
      if (head.isNotEmpty && head != baseTitle) {
        addCandidate(head, 'subtitle_head', year);
      }
    }

    return candidates;
  }

  static bool _isYearToken(String token) {
    final year = int.tryParse(token);
    if (year == null) return false;
    return year >= 1990 && year <= 2099;
  }

  static (double, double, int?) _scoreWithYearBias({
    required double score,
    required int? targetYear,
    required String? rawDate,
  }) {
    if (targetYear == null || rawDate == null) {
      return (score, 0.6, null);
    }

    try {
      final resultYear = DateTime.parse(rawDate).year;
      if (resultYear == targetYear) {
        final adjusted = (score + 0.1).clamp(0.0, 1.0);
        return (adjusted, 0.55, resultYear);
      }

      final adjusted = (score - 0.1).clamp(0.0, 1.0);
      return (adjusted, 0.65, resultYear);
    } catch (_) {
      return (score, 0.6, null);
    }
  }
}

class _SearchCandidate {
  const _SearchCandidate({
    required this.query,
    required this.cleanedTitle,
    required this.year,
    required this.reason,
  });

  final String query;
  final String cleanedTitle;
  final int? year;
  final String reason;
}

