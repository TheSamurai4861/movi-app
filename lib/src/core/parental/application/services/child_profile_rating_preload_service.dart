import 'dart:async';
import 'dart:collection';

import 'package:movi/src/core/parental/domain/repositories/content_rating_repository.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/core/utils/title_cleaner.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';
import 'package:movi/src/shared/domain/services/similarity_service.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

/// État de progression du préchargement
class PreloadProgress {
  const PreloadProgress({
    required this.phase,
    required this.moviesProcessed,
    required this.moviesTotal,
    required this.seriesProcessed,
    required this.seriesTotal,
    required this.elapsedSeconds,
    required this.estimatedSecondsRemaining,
  });

  final PreloadPhase phase;
  final int moviesProcessed;
  final int moviesTotal;
  final int seriesProcessed;
  final int seriesTotal;
  final int elapsedSeconds;
  final int? estimatedSecondsRemaining;

  double get moviesProgress =>
      moviesTotal > 0 ? moviesProcessed / moviesTotal : 0.0;
  double get seriesProgress =>
      seriesTotal > 0 ? seriesProcessed / seriesTotal : 0.0;
  double get overallProgress {
    final total = moviesTotal + seriesTotal;
    if (total == 0) return 0.0;
    return (moviesProcessed + seriesProcessed) / total;
  }
}

enum PreloadPhase { resolvingIds, fetchingRatings, completed }

/// Semaphore pour limiter la concurrence
class _Semaphore {
  _Semaphore(this._max) : _available = _max;

  final int _max;
  int _available;
  final Queue<Completer<void>> _waiters = Queue<Completer<void>>();

  Future<void> acquire() {
    if (_available > 0) {
      _available--;
      return Future<void>.value();
    }
    final c = Completer<void>();
    _waiters.addLast(c);
    return c.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeFirst().complete();
      return;
    }
    _available++;
    if (_available > _max) _available = _max;
  }
}

/// Service de préchargement des ratings pour les profils enfants
class ChildProfileRatingPreloadService {
  ChildProfileRatingPreloadService(
    this._iptvLocal,
    this._ratingRepo,
    this._movieRemote,
    this._tvRemote,
    this._similarity,
    this._cache,
    this._language,
  );

  final IptvLocalRepository _iptvLocal;
  final ContentRatingRepository _ratingRepo;
  final TmdbMovieRemoteDataSource _movieRemote;
  final TmdbTvRemoteDataSource _tvRemote;
  final SimilarityService _similarity;
  final ContentCacheRepository _cache;
  final String _language;

  static const int _maxConcurrent = 5;

  final _progressController = StreamController<PreloadProgress>.broadcast();
  Stream<PreloadProgress> get progress => _progressController.stream;

  /// Lance le préchargement pour les contenus IPTV actifs
  Future<void> preload({
    required Set<String> activeSourceIds,
    void Function()? onCancelled,
  }) async {
    final startTime = DateTime.now();
    final cancelToken = Completer<void>();

    try {
      // Récupérer tous les items IPTV
      final allItems = await _iptvLocal.getAllPlaylistItems(
        accountIds: activeSourceIds,
      );

      // Séparer films et séries, avec et sans tmdb_id
      final moviesWithId = <XtreamPlaylistItem>[];
      final moviesWithoutId = <XtreamPlaylistItem>[];
      final seriesWithId = <XtreamPlaylistItem>[];
      final seriesWithoutId = <XtreamPlaylistItem>[];

      for (final item in allItems) {
        if (item.type == XtreamPlaylistItemType.movie) {
          if (item.tmdbId != null && item.tmdbId! > 0) {
            moviesWithId.add(item);
          } else {
            moviesWithoutId.add(item);
          }
        } else {
          if (item.tmdbId != null && item.tmdbId! > 0) {
            seriesWithId.add(item);
          } else {
            seriesWithoutId.add(item);
          }
        }
      }

      final moviesTotal = moviesWithId.length + moviesWithoutId.length;
      final seriesTotal = seriesWithId.length + seriesWithoutId.length;

      var moviesProcessed = 0;
      var seriesProcessed = 0;

      // Phase 1: Résolution des IDs manquants
      _emitProgress(
        PreloadProgress(
          phase: PreloadPhase.resolvingIds,
          moviesProcessed: moviesProcessed,
          moviesTotal: moviesTotal,
          seriesProcessed: seriesProcessed,
          seriesTotal: seriesTotal,
          elapsedSeconds: DateTime.now().difference(startTime).inSeconds,
          estimatedSecondsRemaining: null,
        ),
      );

      // Résoudre les IDs pour les films
      final resolvedMovieIds = <XtreamPlaylistItem, int>{};
      await _resolveIds(moviesWithoutId, ContentType.movie, cancelToken, (
        resolved,
      ) {
        resolvedMovieIds.addAll(resolved);
        moviesProcessed += resolved.length;
        _emitProgress(
          PreloadProgress(
            phase: PreloadPhase.resolvingIds,
            moviesProcessed: moviesProcessed,
            moviesTotal: moviesTotal,
            seriesProcessed: seriesProcessed,
            seriesTotal: seriesTotal,
            elapsedSeconds: DateTime.now().difference(startTime).inSeconds,
            estimatedSecondsRemaining: null,
          ),
        );
      });

      // Résoudre les IDs pour les séries
      final resolvedSeriesIds = <XtreamPlaylistItem, int>{};
      await _resolveIds(seriesWithoutId, ContentType.series, cancelToken, (
        resolved,
      ) {
        resolvedSeriesIds.addAll(resolved);
        seriesProcessed += resolved.length;
        _emitProgress(
          PreloadProgress(
            phase: PreloadPhase.resolvingIds,
            moviesProcessed: moviesProcessed,
            moviesTotal: moviesTotal,
            seriesProcessed: seriesProcessed,
            seriesTotal: seriesTotal,
            elapsedSeconds: DateTime.now().difference(startTime).inSeconds,
            estimatedSecondsRemaining: null,
          ),
        );
      });

      // Phase 2: Récupération des ratings
      _emitProgress(
        PreloadProgress(
          phase: PreloadPhase.fetchingRatings,
          moviesProcessed: moviesProcessed,
          moviesTotal: moviesTotal,
          seriesProcessed: seriesProcessed,
          seriesTotal: seriesTotal,
          elapsedSeconds: DateTime.now().difference(startTime).inSeconds,
          estimatedSecondsRemaining: null,
        ),
      );

      // Collecter tous les IDs à traiter (avec ID + résolus)
      final movieIdsToFetch = <int>[
        ...moviesWithId.map((item) => item.tmdbId!),
        ...resolvedMovieIds.values,
      ];
      final seriesIdsToFetch = <int>[
        ...seriesWithId.map((item) => item.tmdbId!),
        ...resolvedSeriesIds.values,
      ];

      // Vérifier le cache et filtrer ceux qui ne sont pas en cache
      final movieIdsToFetchFiltered = <int>[];
      for (final id in movieIdsToFetch) {
        final cached = await _ratingRepo.getMinAge(
          type: ContentType.movie,
          tmdbId: id,
        );
        if (cached.minAge == null) {
          movieIdsToFetchFiltered.add(id);
        }
      }

      final seriesIdsToFetchFiltered = <int>[];
      for (final id in seriesIdsToFetch) {
        final cached = await _ratingRepo.getMinAge(
          type: ContentType.series,
          tmdbId: id,
        );
        if (cached.minAge == null) {
          seriesIdsToFetchFiltered.add(id);
        }
      }

      // Mettre à jour les totaux (seulement ceux qui doivent être fetchés)
      final moviesToFetch = movieIdsToFetchFiltered.length;
      final seriesToFetch = seriesIdsToFetchFiltered.length;
      moviesProcessed = moviesTotal - moviesToFetch;
      seriesProcessed = seriesTotal - seriesToFetch;

      // Récupérer les ratings pour les films
      final requestTimes = <Duration>[];
      await _fetchRatings(
        movieIdsToFetchFiltered,
        ContentType.movie,
        cancelToken,
        (count, requestTime) {
          moviesProcessed += count;
          requestTimes.add(requestTime);
          final avgTimeMs = requestTimes.isNotEmpty
              ? requestTimes
                        .map((d) => d.inMilliseconds)
                        .reduce((a, b) => a + b) /
                    requestTimes.length
              : 1000.0;
          final remaining =
              moviesToFetch + seriesToFetch - moviesProcessed - seriesProcessed;
          final estimated = remaining > 0
              ? ((remaining * avgTimeMs) / _maxConcurrent / 1000).round()
              : 0;

          _emitProgress(
            PreloadProgress(
              phase: PreloadPhase.fetchingRatings,
              moviesProcessed: moviesProcessed,
              moviesTotal: moviesTotal,
              seriesProcessed: seriesProcessed,
              seriesTotal: seriesTotal,
              elapsedSeconds: DateTime.now().difference(startTime).inSeconds,
              estimatedSecondsRemaining: estimated > 0 ? estimated : null,
            ),
          );
        },
      );

      // Récupérer les ratings pour les séries
      await _fetchRatings(
        seriesIdsToFetchFiltered,
        ContentType.series,
        cancelToken,
        (count, requestTime) {
          seriesProcessed += count;
          requestTimes.add(requestTime);
          final avgTimeMs = requestTimes.isNotEmpty
              ? requestTimes
                        .map((d) => d.inMilliseconds)
                        .reduce((a, b) => a + b) /
                    requestTimes.length
              : 1000.0;
          final remaining =
              moviesToFetch + seriesToFetch - moviesProcessed - seriesProcessed;
          final estimated = remaining > 0
              ? ((remaining * avgTimeMs) / _maxConcurrent / 1000).round()
              : 0;

          _emitProgress(
            PreloadProgress(
              phase: PreloadPhase.fetchingRatings,
              moviesProcessed: moviesProcessed,
              moviesTotal: moviesTotal,
              seriesProcessed: seriesProcessed,
              seriesTotal: seriesTotal,
              elapsedSeconds: DateTime.now().difference(startTime).inSeconds,
              estimatedSecondsRemaining: estimated > 0 ? estimated : null,
            ),
          );
        },
      );

      // Phase complétée
      _emitProgress(
        PreloadProgress(
          phase: PreloadPhase.completed,
          moviesProcessed: moviesTotal,
          moviesTotal: moviesTotal,
          seriesProcessed: seriesTotal,
          seriesTotal: seriesTotal,
          elapsedSeconds: DateTime.now().difference(startTime).inSeconds,
          estimatedSecondsRemaining: null,
        ),
      );
    } catch (e) {
      if (!cancelToken.isCompleted) {
        _progressController.addError(e);
      }
      rethrow;
    } finally {
      if (!cancelToken.isCompleted) {
        cancelToken.complete();
      }
    }
  }

  /// Résout les IDs TMDB manquants via Search API
  Future<void> _resolveIds(
    List<XtreamPlaylistItem> items,
    ContentType type,
    Completer<void> cancelToken,
    void Function(Map<XtreamPlaylistItem, int> resolved) onProgress,
  ) async {
    if (items.isEmpty) return;

    final semaphore = _Semaphore(_maxConcurrent);
    final resolved = <XtreamPlaylistItem, int>{};
    final batchSize = 20;

    for (var i = 0; i < items.length; i += batchSize) {
      if (cancelToken.isCompleted) break;

      final batch = items.skip(i).take(batchSize).toList();
      final batchResults =
          await Future.wait<MapEntry<XtreamPlaylistItem, int?>?>(
            batch.map((item) async {
              await semaphore.acquire();
              try {
                if (cancelToken.isCompleted) return null;

                // Vérifier le cache de résolution d'ID
                final cacheKey = _idResolutionCacheKey(type, item);
                final cached = await _cache.get(cacheKey);
                if (cached != null) {
                  final cachedId = _parseInt(cached['tmdb_id']);
                  if (cachedId != null && cachedId > 0) {
                    return MapEntry(item, cachedId);
                  }
                }

                // Rechercher dans TMDB
                final cleaned = TitleCleaner.cleanWithYear(item.title);
                if (cleaned.cleanedTitle.isEmpty) return null;

                final searchResults = type == ContentType.movie
                    ? await _movieRemote.searchMovies(
                        cleaned.cleanedTitle,
                        language: _language,
                      )
                    : await _tvRemote.searchShows(
                        cleaned.cleanedTitle,
                        language: _language,
                      );

                if (searchResults.isEmpty) return null;

                // Trouver le meilleur match
                final targetYear = cleaned.year ?? item.releaseYear;
                double bestScore = 0.0;
                int? bestMatchId;

                for (final result in searchResults) {
                  final resultTitle = type == ContentType.movie
                      ? (result as dynamic).title
                      : (result as dynamic).name;
                  final score = _similarity.score(
                    cleaned.cleanedTitle,
                    resultTitle,
                  );

                  // Bonus si l'année correspond
                  if (targetYear != null) {
                    final resultDate = type == ContentType.movie
                        ? (result as dynamic).releaseDate
                        : (result as dynamic).firstAirDate;
                    if (resultDate != null) {
                      try {
                        final resultYear = DateTime.parse(resultDate).year;
                        if ((resultYear - targetYear).abs() <= 1) {
                          final adjustedScore = (score + 0.1).clamp(0.0, 1.0);
                          if (adjustedScore > bestScore) {
                            bestScore = adjustedScore;
                            bestMatchId = (result as dynamic).id;
                          }
                          continue;
                        }
                      } catch (_) {
                        // Ignorer les erreurs de parsing
                      }
                    }
                  }

                  if (score > bestScore) {
                    bestScore = score;
                    bestMatchId = (result as dynamic).id;
                  }
                }

                // Seuil minimum de 0.6
                if (bestScore >= 0.6 &&
                    bestMatchId != null &&
                    bestMatchId > 0) {
                  // Mettre en cache la résolution
                  await _cache.put(
                    key: cacheKey,
                    type: 'tmdb_id_resolution',
                    payload: <String, dynamic>{
                      'tmdb_id': bestMatchId,
                      'resolved_at': DateTime.now().toIso8601String(),
                    },
                  );
                  return MapEntry(item, bestMatchId);
                }

                return null;
              } catch (e) {
                // Ignorer les erreurs de recherche
                return null;
              } finally {
                semaphore.release();
              }
            }),
          );

      // Collecter les résultats
      final batchResolved = <XtreamPlaylistItem, int>{};
      for (final result in batchResults) {
        if (result != null && result.value != null) {
          batchResolved[result.key] = result.value!;
        }
      }

      if (batchResolved.isNotEmpty) {
        resolved.addAll(batchResolved);
        onProgress(batchResolved);
      }
    }
  }

  /// Récupère les ratings pour une liste d'IDs
  Future<void> _fetchRatings(
    List<int> ids,
    ContentType type,
    Completer<void> cancelToken,
    void Function(int count, Duration requestTime) onProgress,
  ) async {
    if (ids.isEmpty) return;

    final semaphore = _Semaphore(_maxConcurrent);
    final batchSize = 20;
    var processed = 0;

    for (var i = 0; i < ids.length; i += batchSize) {
      if (cancelToken.isCompleted) break;

      final batch = ids.skip(i).take(batchSize).toList();
      final batchStart = DateTime.now();

      await Future.wait(
        batch.map((id) async {
          await semaphore.acquire();
          try {
            if (cancelToken.isCompleted) return;

            await _ratingRepo.getMinAge(type: type, tmdbId: id);
            processed++;
          } catch (e) {
            // Ignorer les erreurs (404, timeout, etc.)
          } finally {
            semaphore.release();
          }
        }),
      );

      final batchTime = DateTime.now().difference(batchStart);
      onProgress(processed, batchTime);
      processed = 0;
    }
  }

  String _idResolutionCacheKey(ContentType type, XtreamPlaylistItem item) {
    final normalizedTitle = item.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .substring(0, item.title.length > 50 ? 50 : item.title.length);
    final year = item.releaseYear ?? 0;
    return 'tmdb_id_resolution_${type.name}_${normalizedTitle}_$year';
  }

  int? _parseInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  void _emitProgress(PreloadProgress progress) {
    if (!_progressController.isClosed) {
      _progressController.add(progress);
    }
  }

  void dispose() {
    _progressController.close();
  }
}
